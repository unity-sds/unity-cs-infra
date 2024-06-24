import sys
import os
import time
import boto3
import logging
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
log_file = f'/home/ubuntu/uninstall_aws_resources_mc_{timestamp}.log'

# Configure logging
logging.basicConfig(filename=log_file, level=logging.DEBUG,
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

def setup_driver():
    options = Options()
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('window-size=1024x768')
    grid_url = 'http://localhost:4444/wd/hub'
    driver = webdriver.Remote(command_executor=grid_url, options=options)
    return driver

def get_ec2_instance_id(project, venue):
    ec2 = boto3.resource('ec2', region_name='us-west-2')
    instance_name = "Unity Management Console (" + project + "/" + venue + ")"
    logging.info(f"Looking for EC2 instance with name: {instance_name}")
    print(f"Looking for EC2 instance with name: {instance_name}")

    instances = ec2.instances.filter(
        Filters=[{'Name': 'tag:Name', 'Values': [instance_name]}]
    )

    instance_ids = [instance.id for instance in instances]

    if instance_ids:
        for instance_id in instance_ids:
            logging.info(f"EC2 ID: {instance_id}")
            print(f"EC2 ID: {instance_id}")
        return instance_ids[0]  # Return the first instance ID found
    else:
        logging.warning("No EC2 instance found.")
        print("No EC2 instance found.")
        return None

def wait_for_uninstall_complete(log_group_name, log_stream_name, completion_message, check_interval=10, timeout=1800):
    cw_client = boto3.client('logs', region_name='us-west-2')
    start_time = time.time()
    
    failure_messages = [
        "FAILED TO DESTROY ALL COMPONENTS",
        "FAILED TO REMOVE S3 BUCKET",
        "FAILED TO REMOVE DYNAMODB TABLE"
    ]

    while True:
        elapsed_time = time.time() - start_time
        if elapsed_time > timeout:
            logging.error("Timeout waiting for uninstall to complete.")
            print("Timeout waiting for uninstall to complete.")
            return False

        try:
            response = cw_client.get_log_events(
                logGroupName=log_group_name,
                logStreamName=log_stream_name,
                startFromHead=False
            )
            events = response.get('events', [])
            for event in events:
                message = event.get('message', '')
                if completion_message in message:
                    logging.info("Uninstall of MC AWS Resources completed successfully.")
                    print("Uninstall of MC AWS Resources completed successfully.")
                    return True
                for failure_message in failure_messages:
                    if failure_message in message:
                        logging.error(f"Failure detected: {message}")
                        return False
        except Exception as e:
            logging.error(f"Error checking logs: {e}")
            return False

        time.sleep(check_interval)

def uninstall_aws_resources(project, venue):
    ssm = boto3.client('ssm', region_name='us-west-2')
    parameter_name = '/unity/' + project + '/' + venue + '/management/httpd/loadbalancer-url'
    logging.info(f"Retrieved SSM parameter for MC URL: {parameter_name}")
    try:
        response = ssm.get_parameter(Name=parameter_name)
        url = response['Parameter']['Value']
        logging.info(f"Retrieved SSM parameter: {url}")
    except Exception as e:
        logging.error(f"Error retrieving SSM parameter: {e}")
        return

    driver = setup_driver()
    try:
        driver.get(url)
        time.sleep(2)

        uninstall_link = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//a[contains(@class, 'inline-flex') and contains(text(), 'Uninstall')]"))
        )
        driver.execute_script("arguments[0].click();", uninstall_link)
        time.sleep(2)

        go_button = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//button[contains(text(), 'Go!')]"))
        )
        driver.execute_script("arguments[0].click();", go_button)
        logging.info("Uninstall process initiated successfully.")
        print("Uninstall process initiated successfully.")

    except TimeoutException:
        logging.error("Failed to perform uninstall - either elements were not clickable or not found as expected.")
        print("Failed to perform uninstall - either elements were not clickable or not found as expected.")
    finally:
        driver.quit()

    instance_id = get_ec2_instance_id(project, venue)
    if instance_id:
        log_stream_name = instance_id
        wait_for_uninstall_complete("managementconsole", log_stream_name, "UNITY MANAGEMENT CONSOLE UNINSTALL COMPLETE")

if __name__ == "__main__":
    arguments = sys.argv[1:]
    if len(arguments) < 2:
        print("Usage: python uninstall_aws_resources_mc.py <PROJECT_NAME> <VENUE_NAME>")
        logging.error("Usage: python uninstall_aws_resources_mc.py <PROJECT_NAME> <VENUE_NAME>")
        sys.exit(1)

    project = arguments[0]
    venue = arguments[1]

    uninstall_aws_resources(project, venue)
