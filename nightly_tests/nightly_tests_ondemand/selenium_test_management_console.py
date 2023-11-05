import os
import time
import pytest
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from urllib.parse import urlparse, urlunparse

# Retrieve the credentials and the URL from the environment variables
mc_username = os.getenv('MC_USERNAME')
mc_password = os.getenv('MC_PASSWORD')
management_console_url = os.getenv('MANAGEMENT_CONSOLE_URL')

# Parse the original URL
parsed_url = urlparse(management_console_url)

# Reconstruct the URL with the username and password included
new_netloc = f"{mc_username}:{mc_password}@{parsed_url.hostname}"
if parsed_url.port:
    new_netloc += f":{parsed_url.port}"

# Construct the new URL
new_url = urlunparse((parsed_url.scheme, new_netloc, parsed_url.path, parsed_url.params, parsed_url.query, parsed_url.fragment))


URL_WITH_CRED = new_url
URL_WITHOUT_CRED = os.getenv('MANAGEMENT_CONSOLE_URL')

IMAGE_DIR = 'selenium_unity_images'

@pytest.fixture(scope='module')
def driver():
    options = Options()
    # options.add_argument('--headless') # Uncomment this if you run headless mode
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')

    # Define the Selenium Grid hub address
    grid_url = 'http://localhost:4444/wd/hub'

    # Create a Remote WebDriver
    driver = webdriver.Remote(
        command_executor=grid_url,
        options=options
    )

    # Your existing code to create directory for images
    if not os.path.exists(IMAGE_DIR):
        os.makedirs(IMAGE_DIR)

    # Navigate to the URLs
    driver.get(URL_WITH_CRED)
    driver.get(URL_WITHOUT_CRED)
    time.sleep(1)

    yield driver
    driver.quit() 

def test_login(driver):
    # Assert the page title to check the navigation worked as expected
    screenshot_path = os.path.join(IMAGE_DIR, 'screenshot_after_login.png')
    driver.save_screenshot(screenshot_path)

    assert driver.current_url.endswith('/ui/landing'), "Navigation to home page failed"
    assert driver.title == 'Unity Management Console', "The page title should be Unity Management Console"

def test_click_go_button(driver):
    # Locate the Go! button and click it
    go_button = driver.find_element(By.CSS_SELECTOR, 'a.btn.btn-primary[href="/ui/setup"]')
    go_button.click()
    time.sleep(1)  
    
    # Take a screenshot
    screenshot_path = os.path.join(IMAGE_DIR, 'screenshot_after_clicking_go_button.png')
    driver.save_screenshot(screenshot_path)
    
    assert driver.current_url.endswith('/ui/setup'), "Navigation to setup page failed"

def test_logout(driver):
    go_button = driver.find_element(By.CSS_SELECTOR, 'a.nav-link[href="/logout"]')
    go_button.click()
    time.sleep(8)

    screenshot_path = os.path.join(IMAGE_DIR, 'screenshot_after_logout.png')
    driver.save_screenshot(screenshot_path)
    assert driver.current_url.endswith('/logout'), "Logout failed"
