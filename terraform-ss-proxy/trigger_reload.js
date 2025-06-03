const https = require('https');
const { SQSClient, SendMessageCommand } = require('@aws-sdk/client-sqs');

const sqs = new SQSClient({});

// Configuration - set these as environment variables in Lambda
const APACHE_HOST = process.env.APACHE_HOST || 'www.dev.mdps.mcp.nasa.gov';
const APACHE_PORT = process.env.APACHE_PORT || '4443';
const RELOAD_TOKEN = process.env.RELOAD_TOKEN;
const RELOAD_PATH = '/reload-config';
const SQS_QUEUE_URL = process.env.SQS_QUEUE_URL;
const RELOAD_DELAY = parseInt(process.env.RELOAD_DELAY) || 15; // seconds

exports.handler = async (event) => {
    console.log('Lambda triggered by event:', JSON.stringify(event, null, 2));
    
    // Validate required configuration
    if (!RELOAD_TOKEN) {
        console.error('RELOAD_TOKEN environment variable is required');
        return {
            statusCode: 500,
            body: JSON.stringify({ error: 'Missing RELOAD_TOKEN configuration' })
        };
    }
    
    try {
        // Check if this is an S3 event or SQS event
        if (event.Records && event.Records[0].eventSource === 'aws:s3') {
            return await handleS3Event(event);
        } else if (event.Records && event.Records[0].eventSource === 'aws:sqs') {
            return await handleSQSEvent(event);
        } else {
            console.log('Unknown event source');
            return {
                statusCode: 400,
                body: JSON.stringify({ error: 'Unknown event source' })
            };
        }
    } catch (error) {
        console.error('Error processing event:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({
                error: 'Failed to process event',
                details: error.message
            })
        };
    }
};

async function handleS3Event(event) {
    console.log('Processing S3 event');
    
    if (!SQS_QUEUE_URL) {
        console.error('SQS_QUEUE_URL environment variable is required for S3 events');
        return {
            statusCode: 500,
            body: JSON.stringify({ error: 'Missing SQS_QUEUE_URL configuration' })
        };
    }
    
    // Process S3 event records
    const s3Events = event.Records || [];
    const relevantEvents = s3Events.filter(record => {
        const eventName = record.eventName;
        const objectKey = record.s3?.object?.key || '';
        
        // Only process PUT/POST/DELETE events for .conf files
        return (eventName.startsWith('ObjectCreated') || 
                eventName.startsWith('ObjectRemoved')) && 
               objectKey.endsWith('.conf');
    });
    
    if (relevantEvents.length === 0) {
        console.log('No relevant S3 events found (looking for .conf file changes)');
        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'No config file changes detected' })
        };
    }
    
    console.log(`Found ${relevantEvents.length} relevant config file changes`);
    
    // Calculate next reload boundary (rounded up to next RELOAD_DELAY interval)
    const now = Math.floor(Date.now() / 1000);
    const nextBoundary = Math.ceil(now / RELOAD_DELAY) * RELOAD_DELAY;
    const delaySeconds = Math.max(0, nextBoundary - now);
    
    // Send message with time-based deduplication to ensure proper throttling
    const sqsParams = {
        QueueUrl: SQS_QUEUE_URL,
        MessageBody: 'S3 Config Changed',
        MessageGroupId: 'apache-config-reload',
        MessageDeduplicationId: nextBoundary.toString(), // Time-based deduplication
        DelaySeconds: delaySeconds // Delay until the boundary timestamp
    };
    
    try {
        const command = new SendMessageCommand(sqsParams);
        const result = await sqs.send(command);
        console.log('Message sent to SQS:', result.MessageId);
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: `Config change notification sent to SQS for reload at ${new Date(nextBoundary * 1000).toISOString()}`,
                messageId: result.MessageId,
                eventsProcessed: relevantEvents.length,
                nextBoundary: nextBoundary,
                delaySeconds: delaySeconds
            })
        };
    } catch (sqsError) {
        console.error('Failed to send SQS message:', sqsError);
        throw sqsError;
    }
}

async function handleSQSEvent(event) {
    console.log('Processing SQS event');
    
    // Process the SQS message and trigger reload immediately
    // The delay was already handled by SQS DelaySeconds
    const results = [];
    
    for (const record of event.Records) {
        try {
            const messageBody = record.body;
            console.log('Processing SQS message:', messageBody);
            
            // Trigger Apache reload immediately
            const reloadResult = await makeReloadRequest();
            console.log('Apache reload completed:', reloadResult);
            
            results.push({
                messageId: record.messageId,
                status: 'completed',
                reloadResult: reloadResult
            });
            
        } catch (messageError) {
            console.error('Error processing SQS message:', messageError);
            results.push({
                messageId: record.messageId,
                status: 'error',
                error: messageError.message
            });
        }
    }
    
    return {
        statusCode: 200,
        body: JSON.stringify({
            message: 'SQS messages processed',
            results: results
        })
    };
}


function makeReloadRequest() {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: APACHE_HOST,
            port: APACHE_PORT,
            path: RELOAD_PATH,
            method: 'GET',
            headers: {
                'X-Reload-Token': RELOAD_TOKEN,
                'User-Agent': 'AWS-Lambda-S3-Trigger/1.0'
            },
            // For self-signed certificates or testing
            rejectUnauthorized: process.env.NODE_TLS_REJECT_UNAUTHORIZED !== '0'
        };
        
        const req = https.request(options, (res) => {
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                console.log(`Apache reload response (${res.statusCode}):`, data);
                
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve({
                        statusCode: res.statusCode,
                        response: data
                    });
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                }
            });
        });
        
        req.on('error', (error) => {
            console.error('Request error:', error);
            reject(error);
        });
        
        // Set timeout (shorter since lambda timeout is 15s)
        req.setTimeout(10000, () => {
            req.destroy();
            reject(new Error('Request timeout'));
        });
        
        req.end();
    });
}