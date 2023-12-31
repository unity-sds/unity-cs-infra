import os
import time
import pytest
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support import expected_conditions as EC
from urllib.parse import urlparse, urlunparse

# Global variable for the screenshots directory
IMAGE_DIR = 'selenium_unity_images'

# Function to create a new Selenium driver
@pytest.fixture(scope="session")
def driver():
    options = Options()
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')

    grid_url = 'http://localhost:4444/wd/hub'

    # Create a Remote WebDriver
    driver = webdriver.Remote(
        command_executor=grid_url,
        options=options
    )
    yield driver
    driver.quit()

# Function to navigate to the management console URL with credentials
def test_navigate_to_url_with_cred(driver, test_results):
#    mc_username = os.getenv('MC_USERNAME')
#    mc_password = os.getenv('MC_PASSWORD')
#    management_console_url = os.getenv('MANAGEMENT_CONSOLE_URL')
    mc_username = 'admin'
    mc_password = 'unity'
    management_console_url = 'http://unity-on-demand-alb-sk16y-884072460.us-west-2.elb.amazonaws.com:8080/ui/landing'

    # Construct the URL with credentials
    parsed_url = urlparse(management_console_url)
    new_netloc = f"{mc_username}:{mc_password}@{parsed_url.hostname}"
    if parsed_url.port:
        new_netloc += f":{parsed_url.port}"
    new_url = urlunparse((parsed_url.scheme, new_netloc, parsed_url.path, parsed_url.params, parsed_url.query, parsed_url.fragment))
    URL_WITH_CRED = new_url
    URL_WITHOUT_CRED = management_console_url

    driver.get(URL_WITH_CRED)
    driver.get(URL_WITHOUT_CRED)
    time.sleep(2)  # Wait for the page to load

    assert driver.current_url == URL_WITHOUT_CRED, "URL does not match the expected URL without credentials"
    # Create directory for images if it doesn't exist
    if not os.path.exists(IMAGE_DIR):
        os.makedirs(IMAGE_DIR)

# Fixture to provide the URL without credentials
@pytest.fixture(scope="session")
def url_without_cred():
    # Get the management console URL from the environment variable
    management_console_url = os.getenv('MANAGEMENT_CONSOLE_URL')
    return management_console_url

# Function to test login
def test_login_to_mc_console(driver, test_results):

    # Take a screenshot after login attempt
    screenshot_path = os.path.join(IMAGE_DIR, 'screenshot_after_login.png')
    driver.save_screenshot(screenshot_path)

    # Assertions to validate successful login
    assert driver.current_url.endswith('/ui/landing'), "Navigation to home page failed"
    assert driver.title == 'Unity Management Console', "The page title should be Unity Management Console"

# Function to test clicking the Go! button
def test_initiate_core_setup(driver, test_results):
    try:
        # Find and click the Go button
        go_button = WebDriverWait(driver, 20).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, 'a.btn.btn-primary[href="/ui/setup"]'))
        )
        go_button.click()

        # Wait for the URL to change to the setup page
        WebDriverWait(driver, 10).until(EC.url_contains('/ui/setup'))

    except TimeoutException:
        raise Exception("Failed to navigate to setup page - either the Go button was not clickable or the URL did not change as expected.")

    # Take a screenshot
    screenshot_path = os.path.join(IMAGE_DIR, 'screenshot_after_clicking_go_button.png')
    driver.save_screenshot(screenshot_path)

    # Assert the current URL ends with '/ui/setup'
    assert driver.current_url.endswith('/ui/setup'), "Navigation to setup page failed"

def test_input_venue_name(driver, test_results):
    venue_name = "TEST-VENUE"
    element_id = "venue"

    try:
        # Locate the text box and enter the venue name
        text_box = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.ID, element_id))
        )
        text_box.clear()
        text_box.send_keys(venue_name)

    except TimeoutException:
        raise Exception(f"Failed to find or interact with the text box for venue name (ID: {element_id}).")

    # Assert that the venue name was correctly entered
    assert text_box.get_attribute('value') == venue_name, "Venue name not correctly entered."

    # Take a screenshot after setting the venue name
    screenshot_path = os.path.join(IMAGE_DIR, 'screenshot_after_setting_venue_name.png')
    driver.save_screenshot(screenshot_path)

def test_input_project_name(driver, test_results):
    project_name = "TEST-PROJECT"
    element_id = "project"

    try:
        # Locate the text box and enter the project name
        text_box = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.ID, element_id))
        )
        text_box.clear()
        text_box.send_keys(project_name)

    except TimeoutException:
        raise Exception(f"Failed to find or interact with the text box for project name (ID: {element_id}).")

    # Assert that the project name was correctly entered
    assert text_box.get_attribute('value') == project_name, "Project name not correctly entered."

    # Take a screenshot after setting the project name
    screenshot_path = os.path.join(IMAGE_DIR, 'screenshot_after_setting_project_name.png')
    driver.save_screenshot(screenshot_path)


def test_core_setup_save_btn(driver, test_results):
    try:
        # Find and click the Save button
        save_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//button[@type='submit'][contains(@class, 'st-button large mt-5')]"))
        )
        save_button.click()

    except TimeoutException:
        raise Exception("Failed to find or click the core'Save' button within the specified time.")

    # Take a screenshot after clicking the Save button
    screenshot_path = os.path.join(IMAGE_DIR, 'screenshot_after_clicking_save_button.png')
    driver.save_screenshot(screenshot_path)
        
def test_return_to_marketplace(driver, url_without_cred, test_results):
    # Navigate to the URL without credentials
    driver.get(url_without_cred)
    time.sleep(5)
    driver.refresh()
    time.sleep(5)
    driver.refresh()
    time.sleep(5)

    # Take a screenshot after navigating
    screenshot_path = os.path.join(IMAGE_DIR, 'screenshot_after_navigating.png')
    driver.save_screenshot(screenshot_path)

    try:
        # Find and click the 'Go to Marketplace' button
        go_button = WebDriverWait(driver, 20).until(
            EC.element_to_be_clickable((By.XPATH, "//a[@href='/ui/marketplace'][contains(@class, 'btn btn-primary')]"))
        )
        go_button.click()

        # Wait for the URL to update and check it ends with '/ui/marketplace'
        WebDriverWait(driver, 20).until(EC.url_contains('/ui/marketplace'))

    except TimeoutException:
        raise Exception("Failed to navigate to the marketplace - either the button was not clickable or the URL did not change as expected.")

    assert driver.current_url.endswith('/ui/marketplace'), "URL does not end with '/ui/marketplace'"

    # Take a screenshot for confirmation
    screenshot_path = os.path.join(IMAGE_DIR, 'screenshot_after_clicking_go_button.png')
    driver.save_screenshot(screenshot_path)

def test_grab_terminal_output(driver, test_results):
    element_selector = '.terminal'

    try:
        # Find the terminal output element
        terminal_output_element = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.CSS_SELECTOR, element_selector))
        )

    except TimeoutException:
        raise Exception("Failed to find or load the terminal output element within the specified time.")

    # Retrieve the text from the terminal output
    lines = terminal_output_element.find_elements(By.TAG_NAME, 'div')
    output_text = "\n".join([line.text for line in lines])

    # Assert that the output text contains "success"
    assert "success" in output_text.lower(), "Success not found in terminal output"

    # Optional
    return output_text

def test_install_eks(driver, test_results):
    try:
        # Locate and click the Install Application button
        install_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, "button.st-button.large.float-end"))
        )
        install_button.click()

        # Wait for the URL to update
        WebDriverWait(driver, 10).until(EC.url_contains('/ui/install'))

    except TimeoutException:
        raise Exception("Failed to install EKS - either the button was not clickable or the URL did not update as expected.")

    assert driver.current_url.endswith('/ui/install'), "URL does not end with '/ui/install'"
    # Screenshot logic here
    screenshot_path = os.path.join(IMAGE_DIR, 'screenshot_after_clicking_install_button.png')
    driver.save_screenshot(screenshot_path)
        
def test_eks_module_name(driver, test_results):
    module_name = "unity-cs-selenium-name"
    element_id = "module"

    try:
        text_box = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.ID, element_id))
        )
    except TimeoutException:
        raise Exception(f"Textbox for module name (ID: {element_id}) not found.")

    text_box.clear()
    text_box.send_keys(module_name)
    assert text_box.get_attribute('value') == module_name, "Module name not correctly entered."
    # Screenshot logic
    screenshot_path = os.path.join(IMAGE_DIR, f'screenshot_after_setting_module_name.png')
    driver.save_screenshot(screenshot_path)

def test_eks_module_branch(driver, test_results):
    branch_name = "main"
    element_id = "branch"

    try:
        text_box = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.ID, element_id))
        )
    except TimeoutException:
        raise Exception(f"Textbox for branch name (ID: {element_id}) not found.")

    text_box.clear()
    text_box.send_keys(branch_name)
    assert text_box.get_attribute('value') == branch_name, "Branch name not correctly entered."
    # Screenshot logic here
    screenshot_path = os.path.join(IMAGE_DIR, f'screenshot_after_setting_branch_name.png')
    driver.save_screenshot(screenshot_path)

def test_click_first_button(driver, test_results):
    button_class = 'default-btn.next-step.svelte-1pvzwgg'

    try:
        button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CLASS_NAME, button_class))
        )
        button.click()
    except TimeoutException:
        raise Exception(f"Failed to find or click the first button (class: {button_class}).")

    # Generate a screenshot
    screenshot_name = 'screenshot_after_clicking_first_button.png'
    screenshot_path = os.path.join(IMAGE_DIR, screenshot_name)
    driver.save_screenshot(screenshot_path)

def test_click_second_button(driver, test_results):
    button_class = 'default-btn.next-step.svelte-1pvzwgg'

    try:
        button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CLASS_NAME, button_class))
        )
        button.click()
    except TimeoutException:
        raise Exception(f"Failed to find or click the second button (class: {button_class}).")

    # Generate a screenshot
    screenshot_name = 'screenshot_after_clicking_second_button.png'
    screenshot_path = os.path.join(IMAGE_DIR, screenshot_name)
    driver.save_screenshot(screenshot_path)

def test_click_third_button(driver, test_results):
    button_class = 'default-btn.next-step.svelte-1pvzwgg'

    try:
        button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CLASS_NAME, button_class))
        )
        button.click()
    except TimeoutException:
        raise Exception(f"Failed to find or click the third button (class: {button_class}).")

    # Generate a screenshot
    screenshot_name = 'screenshot_after_clicking_third_button.png'
    screenshot_path = os.path.join(IMAGE_DIR, screenshot_name)
    driver.save_screenshot(screenshot_path)

def test_click_fourth_button(driver, test_results):
    button_class = 'default-btn.next-step.svelte-1pvzwgg'

    try:
        button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CLASS_NAME, button_class))
        )
        button.click()
    except TimeoutException:
        raise Exception(f"Failed to find or click the third button (class: {button_class}).")

    # Generate a screenshot
    screenshot_name = 'screenshot_after_clicking_third_button.png'
    screenshot_path = os.path.join(IMAGE_DIR, screenshot_name)
    driver.save_screenshot(screenshot_path)

def test_click_fith_button(driver, test_results):
    button_class = 'btn.btn-primary.svelte-1pvzwgg'

    try:
        button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CLASS_NAME, button_class))
        )
        button.click()
    except TimeoutException:
        raise Exception(f"Failed to find or click the fourth button (class: {button_class}).")

    # Generate a screenshot
    screenshot_name = 'screenshot_after_clicking_fourth_button.png'
    screenshot_path = os.path.join(IMAGE_DIR, screenshot_name)
    driver.save_screenshot(screenshot_path)


def test_click_fourth_button(driver, test_results):
    button_class = 'btn.btn-primary.svelte-1pvzwgg'

    try:
        button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CLASS_NAME, button_class))
        )
        button.click()
    except TimeoutException:
        raise Exception(f"Failed to find or click the fourth button (class: {button_class}).")

    # Generate a screenshot
    screenshot_name = 'screenshot_after_clicking_fourth_button.png'
    screenshot_path = os.path.join(IMAGE_DIR, screenshot_name)
    driver.save_screenshot(screenshot_path)


def test_grab_terminal_output_two(driver, test_results):
    element_selector = '.terminal'

    try:
        # Find the terminal output element
        terminal_output_element = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.CSS_SELECTOR, element_selector))
        )
    except TimeoutException:
        raise Exception("Failed to find or load the terminal output element within the specified time.")

    # Retrieve the text from the terminal output
    lines = terminal_output_element.find_elements(By.TAG_NAME, 'div')
    output_text = "\n".join([line.text for line in lines])

    # Assert that the output text contains "success"
    assert "success" in output_text.lower(), "Success not found in terminal output"

    return output_text
def pytest_sessionfinish(session, exitstatus):
    print_table(session.results)
