import os
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
import time

def setup_driver():

    options = Options()
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('window-size=1024x768')
    grid_url = 'http://localhost:4444/wd/hub'

    # Create a Remote WebDriver
    driver = webdriver.Remote(
        command_executor=grid_url,
        options=options
    )

    return driver



def navigate_to_mc_console():
    # Take a screenshot after login attempt
    management_console_url = os.getenv('MANAGEMENT_CONSOLE_URL')
    
    driver = setup_driver
    driver.get(management_console_url)
    time.sleep(2)  # Wait for the page to load
    expected_url = management_console_url.rstrip('/') + '/landing'  # Ensures no double slashes if URL_WITHOUT_CRED ends with a slash
    assert driver.current_url.lower() == expected_url.lower(), f"URL does not match the expected URL without credentials. Expected: {expected_url}, but got: {driver.current_url}"

    # Print the current URL for debugging
    print("Current URL:", driver.current_url)

    # Assertions to validate successful login
    assert driver.current_url.endswith('/ui/landing'), f"Navigation to home page failed. Current URL: {driver.current_url}"
    assert driver.title == 'Unity Management Console', "The page title should be Unity Management Console"

def bootstrap_process_status():
    try:
        # Find the element that contains the bootstrap status message
        bootstrap_status_element = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.CSS_SELECTOR, 'h5.text-xl'))
        )
        status_message = bootstrap_status_element.text

        # Take a screenshot for documentation

        # Check if the message indicates a failure
        assert "The Bootstrap Process Failed" not in status_message, "Bootstrap process failed"

    except TimeoutException:
        raise Exception("Failed to find the bootstrap status message within the specified time.")



if __name__ == "__main__":
    uninstall_aws_resources()

