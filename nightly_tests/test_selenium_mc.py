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
screenshot_counter = 1
# Function to create a new Selenium driver
@pytest.fixture(scope="session")
def driver():
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
    yield driver
    driver.quit()
# Function to save screenshot
def save_screenshot(driver, description):
    """
    Save a screenshot with a given description, adding a global counter prefix.
    """
    global screenshot_counter
    screenshot_name = f'{screenshot_counter:02d}_{description}.png'  # Format with leading zeros
    screenshot_path = os.path.join(IMAGE_DIR, screenshot_name)
    driver.save_screenshot(screenshot_path)
    screenshot_counter += 1  # Increment the counter
    return screenshot_path

# Fixture to provide the URL without credentials
@pytest.fixture(scope="session")
def url_without_cred():
    # Get the management console URL from the environment variable
    management_console_url = os.getenv('MANAGEMENT_CONSOLE_URL')
    return management_console_url

# Function to test login
def test_navigate_to_mc_console(driver, test_results):
    # Take a screenshot after login attempt
    management_console_url = os.getenv('MANAGEMENT_CONSOLE_URL')
    URL_WITHOUT_CRED = management_console_url

    driver.get(URL_WITHOUT_CRED)
    time.sleep(2)  # Wait for the page to load
    expected_url = URL_WITHOUT_CRED.rstrip('/') + '/landing'  # Ensures no double slashes if URL_WITHOUT_CRED ends with a slash
    assert driver.current_url.lower() == expected_url.lower(), f"URL does not match the expected URL without credentials. Expected: {expected_url}, but got: {driver.current_url}"

    # Create directory for images if it doesn't exist
    if not os.path.exists(IMAGE_DIR):
        os.makedirs(IMAGE_DIR)

    save_screenshot(driver, 'screenshot_after_navigating_to_URL')

    # Print the current URL for debugging
    print("Current URL:", driver.current_url)

    # Assertions to validate successful login
    assert driver.current_url.endswith('/ui/landing'), f"Navigation to home page failed. Current URL: {driver.current_url}"
    assert driver.title == 'Unity Management Console', "The page title should be Unity Management Console"

def test_bootstrap_process_status(driver, test_results):
    try:
        # Find the element that contains the bootstrap status message
        bootstrap_status_element = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.CSS_SELECTOR, 'h5.text-xl'))
        )
        status_message = bootstrap_status_element.text

        # Take a screenshot for documentation
        save_screenshot(driver, 'screenshot_after_bootstrap_check')

        # Check if the message indicates a failure
        assert "The Bootstrap Process Failed" not in status_message, "Bootstrap process failed"

    except TimeoutException:
        raise Exception("Failed to find the bootstrap status message within the specified time.")

# Function to test clicking the Go! button
def test_initiate_core_setup(driver, test_results):
    try:
        # Find and click the Go button
        go_button = WebDriverWait(driver, 20).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, 'a[href="/management/ui/setup"].bg-blue-600'))
        )
        go_button.click()

        # Wait for the URL to change to the setup page
        WebDriverWait(driver, 10).until(EC.url_contains('/ui/setup'))

    except TimeoutException:
        raise Exception("Failed to navigate to setup page - either the Go button was not clickable or the URL did not change as expected.")

    # Take a screenshot
    save_screenshot(driver, 'screenshot_after_clicking_core_manegement_setup')

    # Assert the current URL ends with '/ui/setup'
    assert driver.current_url.endswith('/ui/setup'), f"Navigation to setup page failed - current URL {driver.current_url}"

def test_core_setup_save_btn(driver, test_results):
    time.sleep(10)
    try:
        # Find and click the Save button
        save_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//button[@type='submit' and contains(@class, 'bg-blue-600')]"))
        )
        save_button.click()
        time.sleep(60)
        # Take a screenshot
        save_screenshot(driver, 'screenshot_after_clicking_core_manegement_save_btn')

    except TimeoutException:
        raise Exception("Failed to find or click the core 'Save' button within the specified time.")

@pytest.fixture
def test_navigate_to_marketplace(driver, url_without_cred, test_results):
    # Navigate to the URL without credentials
    driver.get(url_without_cred)
    time.sleep(5)

    try:
        # Find and click the 'Go to Marketplace' button
        go_button = WebDriverWait(driver, 20).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, "a[href='/management/ui/marketplace'].bg-blue-600"))
        )
        go_button.click()

        # Wait for the URL to update and check it ends with '/ui/marketplace'
        WebDriverWait(driver, 20).until(EC.url_contains('/management/ui/marketplace'))

    except TimeoutException:
        raise Exception("Failed to navigate to the marketplace - either the button was not clickable or the URL did not change as expected.")

    assert driver.current_url.endswith('/management/ui/marketplace'), "URL does not end with '/management/ui/marketplace'"

    # Take a screenshot for confirmation
    save_screenshot(driver, 'screenshot_after_navigating_to_marketplace')

def test_click_install_EKS_btn(driver, test_results, test_navigate_to_marketplace):
    try:
        # Locate and click the Install Application button
        install_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, "button.bg-blue-500.float-right"))
        )
        install_button.click()

        # Wait for the URL to update
        WebDriverWait(driver, 10).until(EC.url_contains('/ui/install'))

    except TimeoutException:
        raise Exception("Failed to install EKS - either the button was not clickable or the URL did not update as expected.")

    assert driver.current_url.endswith('/ui/install'), "URL does not end with '/ui/install'"
    # Screenshot logic here
    save_screenshot(driver, 'screenshot_after_clicking_EKS_install_button')

def test_EKS_module_name(driver, test_results):
    module_name = "EKS-unity-selenium-test"
    element_id = "name"  # ID of the input box
    next_button_class = "btn-gray"  # Class of the Next button

    try:
        # Find and interact with the text box
        text_box = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.ID, element_id))
        )
        text_box.clear()
        text_box.send_keys(module_name)
        assert text_box.get_attribute('value') == module_name, "Module name not correctly entered."


    except TimeoutException:
        raise Exception(f"Failed to find or interact with the specified element (ID: {element_id}).")

    # Screenshot logic
    save_screenshot(driver, 'screenshot_after_setting_module_name')

def test_EKS_module_branch(driver, test_results):
    branch_name = "main"
    element_id = "branch"
    next_button_class = "btn-gray"  # Class of the Next button

    try:
        # Find and click the Next button
        next_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CLASS_NAME, next_button_class))
        )
        next_button.click()

        text_box = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.ID, element_id))
        )
        text_box.clear()
        text_box.send_keys(branch_name)
        

    except TimeoutException:
        raise Exception(f"Textbox for branch name (ID: {element_id}) not found.")

    assert text_box.get_attribute('value') == branch_name, "Branch name not correctly entered."
    # Screenshot logic here
    save_screenshot(driver, 'screenshot_after_setting_branch_name')

def test_click_EKS_install_btns(driver, test_results):
    next_button_xpath = "//button[@type='button'][contains(@class, 'btn-gray') and text()='Next']"
    install_button_xpath = "//button[@type='submit'][contains(@class, 'btn-primary') and text()='Install Software']"

    try:
        next_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, next_button_xpath))
        )
        next_button.click()

        next_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, next_button_xpath))
        )
        next_button.click()

        next_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, next_button_xpath))
        )
        next_button.click()

        install_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, install_button_xpath))
        )
        install_button.click() 

    except TimeoutException:
        raise Exception(f"Failed to find or click the first button (class: {next_button_class}).")

    # Generate a screenshot
    time.sleep(5)
    save_screenshot(driver, 'screenshot_after_clicking_buttons')


def test_grab_terminal_output_EKS(driver, test_results):
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
    assert "Error" in output_text.lower(), "Success not found in terminal output"

    return output_text

def test_click_install_SPS_btn(driver, test_results, test_navigate_to_marketplace):
    try:
        # Locate and click the Install Application button
        install_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, "button.bg-blue-500.float-right"))
        )
        install_button.click()

        # Wait for the URL to update
        WebDriverWait(driver, 10).until(EC.url_contains('/ui/install'))

    except TimeoutException:
        raise Exception("Failed to install EKS - either the button was not clickable or the URL did not update as expected.")

    assert driver.current_url.endswith('/ui/install'), "URL does not end with '/ui/install'"
    # Screenshot logic here
    save_screenshot(driver, 'screenshot_after_clicking_SPS_install_button')

def test_SPS_module_name(driver, test_results):
    module_name = "sps-unity-selenium-test"
    element_id = "name"  # ID of the input box
    next_button_class = "btn-gray"  # Class of the Next button

    try:
        # Find and interact with the text box
        text_box = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.ID, element_id))
        )
        text_box.clear()
        text_box.send_keys(module_name)
        assert text_box.get_attribute('value') == module_name, "Module name not correctly entered."


    except TimeoutException:
        raise Exception(f"Failed to find or interact with the specified element (ID: {element_id}).")

    # Screenshot logic
    save_screenshot(driver, 'screenshot_after_setting_module_name')

def test_SPS_module_branch(driver, test_results):
    branch_name = "main"
    element_id = "branch"
    next_button_class = "btn-gray"  # Class of the Next button

    try:
        # Find and click the Next button
        next_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CLASS_NAME, next_button_class))
        )
        next_button.click()

        text_box = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.ID, element_id))
        )
        text_box.clear()
        text_box.send_keys(branch_name)
        

    except TimeoutException:
        raise Exception(f"Textbox for branch name (ID: {element_id}) not found.")

    assert text_box.get_attribute('value') == branch_name, "Branch name not correctly entered."
    # Screenshot logic here
    save_screenshot(driver, 'screenshot_after_setting_branch_name')

def test_click_SPS_install_btns(driver, test_results):
    next_button_xpath = "//button[@type='button'][contains(@class, 'btn-gray') and text()='Next']"
    install_button_xpath = "//button[@type='submit'][contains(@class, 'btn-primary') and text()='Install Software']"

    try:
        next_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, next_button_xpath))
        )
        next_button.click()

        next_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, next_button_xpath))
        )
        next_button.click()

        next_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, next_button_xpath))
        )
        next_button.click()

        install_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, install_button_xpath))
        )
        install_button.click() 

    except TimeoutException:
        raise Exception(f"Failed to find or click the first button (class: {next_button_class}).")

    # Generate a screenshot
    time.sleep(5)
    save_screenshot(driver, 'screenshot_after_clicking_first_button')


def test_grab_terminal_output_SPS(driver, test_results):
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
    assert "Error" in output_text.lower(), "Success not found in terminal output"

    return output_text


def pytest_sessionfinish(session, exitstatus):
    print_table(session.results)
