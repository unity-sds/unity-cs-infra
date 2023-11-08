import os
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from urllib.parse import urlparse, urlunparse

# Function to create a new Selenium driver
def create_driver():
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
    return driver

# Function to navigate to the management console URL with credentials
def navigate_to_url_with_cred(driver, url_with_cred, url_without_cred, image_dir):
    driver.get(url_with_cred)
    driver.get(url_without_cred)
    time.sleep(1)  # Wait for the page to load

    # Create directory for images if it doesn't exist
    if not os.path.exists(image_dir):
        os.makedirs(image_dir)

# Function to test login
def test_login(driver, image_dir):
    try:
        screenshot_path = os.path.join(image_dir, 'screenshot_after_login.png')
        driver.save_screenshot(screenshot_path)
        assert driver.current_url.endswith('/ui/landing'), "Navigation to home page failed"
        assert driver.title == 'Unity Management Console', "The page title should be Unity Management Console"
        print("Login Test: PASSED")
    except AssertionError as e:
        print(f"Login Test: FAILED - {e}")

# Function to test clicking the Go! button
def test_click_go_button(driver, image_dir):
    try:
        go_button = driver.find_element(By.CSS_SELECTOR, 'a.btn.btn-primary[href="/ui/setup"]')
        go_button.click()
        time.sleep(1)  # Wait for the page to load

        screenshot_path = os.path.join(image_dir, 'screenshot_after_clicking_go_button.png')
        driver.save_screenshot(screenshot_path)
        assert driver.current_url.endswith('/ui/setup'), "Navigation to setup page failed"
        print("Click Go Button Test: PASSED")
    except AssertionError as e:
        print(f"Click Go Button Test: FAILED - {e}")
    
# Main execution
if __name__ == '__main__':
    IMAGE_DIR = 'selenium_unity_images'
    mc_username = os.getenv('MC_USERNAME')
    mc_password = os.getenv('MC_PASSWORD')
    management_console_url = os.getenv('MANAGEMENT_CONSOLE_URL')

    # Construct the URL with credentials
    parsed_url = urlparse(management_console_url)
    new_netloc = f"{mc_username}:{mc_password}@{parsed_url.hostname}"
    if parsed_url.port:
        new_netloc += f":{parsed_url.port}"
    new_url = urlunparse((parsed_url.scheme, new_netloc, parsed_url.path, parsed_url.params, parsed_url.query, parsed_url.fragment))
    URL_WITH_CRED = new_url
    URL_WITHOUT_CRED = management_console_url

    # Create driver
    driver = create_driver()

    # Run the tests
    print("Navigating to URLs...")
    navigate_to_url_with_cred(driver, URL_WITH_CRED, URL_WITHOUT_CRED, IMAGE_DIR)
    
    print("Testing Login...")
    test_login(driver, IMAGE_DIR)
    
    print("Testing Click Go Button...")
    test_click_go_button(driver, IMAGE_DIR)
    
    print("Testing Logout...")
    test_logout(driver, IMAGE_DIR)

    # Quit the driver after the test
    driver.quit()
