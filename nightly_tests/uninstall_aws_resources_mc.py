import sys
import os
import time
import boto3
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

def setup_driver():
    options = Options()
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('window-size=1024x768')
    grid_url = 'http://localhost:4444/wd/hub'
    driver = webdriver.Remote(command_executor=grid_url, options=options)
    return driver


def get_ec2_instance_id(project, venue):
    # Initialize a boto3 EC2 resource
    ec2 = boto3.resource('ec2', region_name='us-west-2')

    # The name of your instance
    instance_name = "Unity Management Console (" + project + "/" + venue + ")"
    print("Looking for EC2 instance with name : " + instance_name)

    # Use filters to find instances by their Name tag
    instances = ec2.instances.filter(
        Filters=[{'Name': 'tag:Name', 'Values': [instance_name]}]
    )

    for instance in instances:
        # Assuming there's only one instance with this name
        return instance.id

    # Return None if no instance found
    return None

def wait_for_uninstall_complete(log_group_name, log_stream_name, completion_message, check_interval=10, timeout=1200):
    cw_client = boto3.client('logs', region_name='us-west-2')
    start_time = time.time()
    
    # failure messages 
    failure_messages = [
        "FAILED TO DESTROY ALL COMPONENTS",
        "FAILED TO REMOVE S3 BUCKET",
        "FAILED TO REMOVE DYNAMODB TABLE"
    ]

    while True:
        elapsed_time = time.time() - start_time
        if elapsed_time > timeout:
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
                    print("Uninstall of MC AWS Resources completed successfully.")
                    return True
                for failure_message in failure_messages:
                    if failure_message in message:
                        print(f"Failure detected: {message}")
                        return False
        except Exception as e:
            print(f"Error checking logs: {e}")
            return False

        time.sleep(check_interval)



def uninstall_aws_resources(project, venue):

    ssm = boto3.client('ssm', region_name='us-west-2')

    # Define the SSM parameter name
    parameter_name = '/unity/' + project + '/' + venue + '/management/httpd/loadbalancer-url'

    # Get the parameter without decrypting
    try:
        response = ssm.get_parameter(Name=parameter_name)
        url = response['Parameter']['Value']
    except Exception as e:
        print(f"Error retrieving SSM parameter: {e}")
        return

    
    driver = setup_driver()
    try:
        driver.get(url)
        time.sleep(2)  # Wait for the page to load

        uninstall_link = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//a[contains(@class, 'inline-flex') and contains(text(), 'Uninstall')]"))
        )
        driver.execute_script("arguments[0].click();", uninstall_link)
        time.sleep(2)  # Adjust this delay as necessary

        go_button = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//button[contains(text(), 'Go!')]"))
        )
        driver.execute_script("arguments[0].click();", go_button)
        print("Uninstall process initiated successfully.")

    except TimeoutException:
        print("Failed to perform uninstall - either elements were not clickable or not found as expected.")
    finally:
        driver.quit()  # Quit the driver as soon as the web interactions are done

    # Retrieve the EC2 instance ID after quitting the driver
    instance_id = get_ec2_instance_id(project, venue)
    # Assuming the log stream name follows a specific pattern with the instance ID
    log_stream_name = instance_id  # Adjust if your log stream naming convention differs
    # Call the function to monitor CloudWatch logs after the driver has been quit
    wait_for_uninstall_complete("managementconsole", log_stream_name, "UNITY MANAGEMENT CONSOLE UNINSTALL COMPLETE")


if __name__ == "__main__":
    # sys.argv[1:] contains the arguments passed to the script
    arguments = sys.argv[1:]
    if len(arguments) < 2:
        print("Usage: python uninstall_aws_resources_mc.py <PROJECT_NAME> <VENUE_NAME>")
        sys.exit(1)

    project = arguments[0]
    venue = arguments[1]

    uninstall_aws_resources(project, venue)

