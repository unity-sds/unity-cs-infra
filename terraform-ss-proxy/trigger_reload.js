const https = require('https');
const { SQSClient, SendMessageCommand, GetQueueAttributesCommand } = require('@aws-sdk/client-sqs');

const sqs = new SQSClient({});

// Configuration - set these as environment variables in Lambda
const APACHE_HOST = process.env.APACHE_HOST || 'www.dev.mdps.mcp.nasa.gov';
const APACHE_PORT = process.env.APACHE_PORT || '4443';
const RELOAD_TOKEN = process.env.RELOAD_TOKEN;
const RELOAD_PATH = '/reload-config';
const SQS_QUEUE_URL = process.env.SQS_QUEUE_URL;
const DEBOUNCE_DELAY = parseInt(process.env.DEBOUNCE_DELAY) || 30; // seconds

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
    
    // Send a generic message to SQS to trigger the debounced reload
    // Use a fixed message body for content-based deduplication
    const sqsParams = {
        QueueUrl: SQS_QUEUE_URL,
        MessageBody: 'S3 Config Changed', // Generic message for deduplication
        MessageGroupId: 'apache-config-reload', // For FIFO queue
        DelaySeconds: 0 // Send immediately to SQS
    };
    
    try {
        const command = new SendMessageCommand(sqsParams);
        const result = await sqs.send(command);
        console.log('Message sent to SQS:', result.MessageId);
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Config change notification sent to SQS',
                messageId: result.MessageId,
                eventsProcessed: relevantEvents.length
            })
        };
    } catch (sqsError) {
        console.error('Failed to send SQS message:', sqsError);
        throw sqsError;
    }
}

async function handleSQSEvent(event) {
    console.log('Processing SQS event');
    
    // Process all SQS messages (though typically there should be only one per invocation)
    const results = [];
    
    for (const record of event.Records) {
        try {
            const messageBody = JSON.parse(record.body);
            console.log('Processing SQS message:', messageBody);
            
            // Implement debouncing by checking if there are newer messages in the queue
            const shouldProceed = await checkIfShouldProceed();
            
            if (!shouldProceed) {
                console.log('Skipping reload - newer messages detected in queue');
                results.push({
                    messageId: record.messageId,
                    status: 'skipped',
                    reason: 'newer_messages_pending'
                });
                continue;
            }
            
            // Wait for the debounce period to allow any in-flight messages to arrive
            console.log(`Waiting ${DEBOUNCE_DELAY} seconds for additional changes...`);
            await new Promise(resolve => setTimeout(resolve, DEBOUNCE_DELAY * 1000));
            
            // Check again after waiting
            const shouldProceedAfterWait = await checkIfShouldProceed();
            
            if (!shouldProceedAfterWait) {
                console.log('Skipping reload after wait - newer messages detected');
                results.push({
                    messageId: record.messageId,
                    status: 'skipped',
                    reason: 'newer_messages_after_wait'
                });
                continue;
            }
            
            // Proceed with Apache reload
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

async function checkIfShouldProceed() {
    if (!SQS_QUEUE_URL) {
        return true; // If no SQS configured, proceed
    }
    
    try {
        // Check if there are messages in the queue
        const command = new GetQueueAttributesCommand({
            QueueUrl: SQS_QUEUE_URL,
            AttributeNames: ['ApproximateNumberOfMessages', 'ApproximateNumberOfMessagesNotVisible']
        });
        const queueAttributes = await sqs.send(command);
        
        const visibleMessages = parseInt(queueAttributes.Attributes.ApproximateNumberOfMessages) || 0;
        const invisibleMessages = parseInt(queueAttributes.Attributes.ApproximateNumberOfMessagesNotVisible) || 0;
        
        console.log(`Queue status - Visible: ${visibleMessages}, In-flight: ${invisibleMessages}`);
        
        // If there are other visible messages, don't proceed (let the newer message handle it)
        return visibleMessages === 0;
        
    } catch (error) {
        console.error('Error checking queue status:', error);
        // If we can't check the queue, proceed to be safe
        return true;
    }
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
        
        // Set timeout
        req.setTimeout(30000, () => {
            req.destroy();
            reject(new Error('Request timeout'));
        });
        
        req.end();
    });
}