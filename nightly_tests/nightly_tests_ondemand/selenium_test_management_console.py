import os
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support import expected_conditions as EC
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
def navigate_to_url_with_cred(driver, url_with_cred, url_without_cred, image_dir, results):
    driver.get(url_with_cred)
    driver.get(url_without_cred)
    time.sleep(2)  # Wait for the page to load

    try:
        assert driver.current_url == url_without_cred, "URL does not match the expected URL without credentials"
        results.append({'name': 'Navigate to URL', 'status': 'PASSED'})
    except AssertionError as e:
        results.append({'name': 'Navigate to URL', 'status': f'FAILED - {e}'})
        
    # Create directory for images if it doesn't exist
    if not os.path.exists(image_dir):
        os.makedirs(image_dir)

# Function to print results in a tabular format
def print_table(results):
    # Determine the width of the table based on the longest test name
    max_name_length = max(len(result['name']) for result in results)
    name_width = max(max_name_length, len('Test Name'))

    # Print the header
    print(f"\n{'Test Name'.ljust(name_width)} | {'Status'}")
    print(f"{'-' * name_width}-+--------")

    # Print each result
    for result in results:
        print(f"{result['name'].ljust(name_width)} | {result['status']}")

# Function to test login
def test_login(driver, image_dir, results):
    try:
        screenshot_path = os.path.join(image_dir, 'screenshot_after_login.png')
        driver.save_screenshot(screenshot_path)
        assert driver.current_url.endswith('/ui/landing'), "Navigation to home page failed"
        assert driver.title == 'Unity Management Console', "The page title should be Unity Management Console"
        results.append({'name': 'Login', 'status': 'PASSED'})
    except AssertionError as e:
        results.append({'name': 'Login', 'status': f'FAILED - {e}'})

# Function to test clicking the Go! button
def test_click_go_button(driver, image_dir, results):
    try:
        go_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, 'a.btn.btn-primary[href="/ui/setup"]'))
        )
        go_button.click()

        WebDriverWait(driver, 10).until(EC.url_contains('/ui/setup')) 

        screenshot_path = os.path.join(image_dir, 'screenshot_after_clicking_go_button.png')
        driver.save_screenshot(screenshot_path)
        assert driver.current_url.endswith('/ui/setup'), "Navigation to setup page failed"
        results.append({'name': 'Click Core Management Btn', 'status': 'PASSED'})
    except AssertionError as e:
        results.append({'name': 'Click Core Management Btn', 'status': f'FAILED - {e}'})
        
def core_management_setup(driver, image_dir, results, text, element_id):
    test_name = f'Enter {element_id} Name'
    try:
        text_box = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.ID, element_id))
        )
    except TimeoutException:
        error_message = f"Element with ID '{element_id}' not found within the given time."
        results.append({'name': test_name, 'status': 'FAILED', 'error': error_message})
        print(error_message)
        return  # Exit the function if the element is not found

    # If the element is found, continue with the rest of the code
    try:
        assert text_box is not None, "Textbox not found."

        text_box.clear()
        text_box.send_keys(text)

        assert text_box.get_attribute('value') == text, "Text not correctly entered."

        screenshot_path = os.path.join(image_dir, f'screenshot_after_input_{text}.png')
        driver.save_screenshot(screenshot_path)

        results.append({'name': test_name, 'status': 'PASSED'})
    except AssertionError as e:
        results.append({'name': test_name, 'status': 'FAILED', 'error': str(e)})
        print(str(e))
        
def core_management_setup_save_btn(driver, image_dir, results):
    test_name = 'Save Button'
    try:
        save_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//button[@type='submit'][contains(@class, 'st-button large mt-5')]"))
        )
        save_button.click()

        screenshot_path = os.path.join(image_dir, 'screenshot_after_clicking_save_button.png')
        driver.save_screenshot(screenshot_path)

        results.append({'name': test_name, 'status': 'PASSED'})

    except Exception as e:
        results.append({'name': test_name, 'status': f'FAILED - {e}'})
        
def go_back_and_goto_marketplace(driver, image_dir, results):
    test_name = 'Go Back and Go To Market'
    try:
        driver.back()

        go_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//a[@href='/ui/marketplace'][contains(@class, 'btn btn-primary')]"))
        )
        go_button.click()

        WebDriverWait(driver, 10).until(EC.url_contains('/ui/marketplace'))
        assert driver.current_url.endswith('/ui/marketplace'), "URL does not end with '/ui/marketplace'"

        # Take a screenshot for confirmation
        screenshot_path = os.path.join(image_dir, 'screenshot_after_clicking_go_button.png')
        driver.save_screenshot(screenshot_path)

        results.append({'name': test_name, 'status': 'PASSED'})

    except Exception as e:
        # Append a failed result with the exception message
        results.append({'name': test_name, 'status': f'FAILED - {e}'})
        
def grab_terminal_output(driver, element_selector, results):
    try:
        terminal_output_element = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.CSS_SELECTOR, element_selector))
        )
        assert terminal_output_element is not None, "Terminal output element not found."

        lines = terminal_output_element.find_elements(By.TAG_NAME, 'div')
        output_text = "\n".join([line.text for line in lines])

        if "success" in output_text.lower():
            results.append({'name': 'Terminal Output', 'status': 'PASSED'})
        else:
            results.append({'name': 'Terminal Output', 'status': 'FAILED - Success not found in terminal output'})

        return output_text

    except Exception as e:
        print(f"Error in grabbing terminal output: {e}")
        results.append({'name': 'Terminal Output', 'status': f'FAILED - {e}'})
        return None

def install_eks(driver, image_dir, results):
    test_name = 'Install EKS'
    try:
        # Locate the Install Application button
        install_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, "button.st-button.large.float-end"))
        )
        assert install_button is not None, "Install Application button not found."

        # Click the button
        install_button.click()
        
        WebDriverWait(driver, 10).until(EC.url_contains('/ui/install'))
        assert driver.current_url.endswith('/ui/install'), "URL does not end with '/ui/install'"
        
        # Take a screenshot for confirmation
        screenshot_path = os.path.join(image_dir, 'screenshot_after_clicking_install_button.png')
        driver.save_screenshot(screenshot_path)

        # Add a passed result
        results.append({'name': test_name, 'status': 'PASSED'})

    except Exception as e:
        # Append a failed result with the exception message
        results.append({'name': test_name, 'status': f'FAILED - {e}'})
def unity_management_setup(driver, image_dir, results, text, element_id):
    test_name = f'Enter {element_id} Name'
    try:
        text_box = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.ID, element_id))
        )
    except TimeoutException:
        error_message = f"Element with ID '{element_id}' not found within the given time."
        results.append({'name': test_name, 'status': 'FAILED', 'error': error_message})
        print(error_message)
        return  # Exit the function if the element is not found

    # If the element is found, continue with the rest of the code
    try:
        assert text_box is not None, "Textbox not found."

        text_box.clear()
        text_box.send_keys(text)

        assert text_box.get_attribute('value') == text, "Text not correctly entered."

        screenshot_path = os.path.join(image_dir, f'screenshot_after_input_{text}.png')
        driver.save_screenshot(screenshot_path)

        results.append({'name': test_name, 'status': 'PASSED'})
    except AssertionError as e:
        results.append({'name': test_name, 'status': 'FAILED', 'error': str(e)})
        print(str(e))

def click_button(driver, image_dir, results, button_class):
    test_name = f'Next Button'
    try:
        # Find and click the button
        button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CLASS_NAME, button_class))
        )
        button.click()

        # Generate a screenshot name based on the button class
        time.sleep(2)
        screenshot_name = f'click_{button_class.replace(" ", "_").replace(".", "_")}.png'
        screenshot_path = os.path.join(image_dir, screenshot_name)
        driver.save_screenshot(screenshot_path)

        results.append({'name': test_name, 'status': 'PASSED'})
    except TimeoutException:
        error_message = f"Button with class '{button_class}' not found or not clickable within the given time."
        results.append({'name': test_name, 'status': 'FAILED', 'error': error_message})
        print(error_message)
    except AssertionError as e:
        results.append({'name': test_name, 'status': 'FAILED', 'error': str(e)})
        print(str(e))

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

    # Create a list to store the results
    test_results = []

    # Create driver
    driver = create_driver()

    # Run the tests
    navigate_to_url_with_cred(driver, URL_WITH_CRED, URL_WITHOUT_CRED, IMAGE_DIR, test_results)  
    
    test_login(driver, IMAGE_DIR, test_results)
    test_click_go_button(driver, IMAGE_DIR, test_results)
    core_management_setup(driver, IMAGE_DIR, test_results, "unity-cs-selenium-project", "project")
    core_management_setup(driver, IMAGE_DIR, test_results, "unity-cs-selenium-venue", "venue")
    core_management_setup_save_btn(driver, IMAGE_DIR, test_results)
    grab_terminal_output(driver, ".terminal", test_results)
    go_back_and_goto_marketplace(driver, IMAGE_DIR, test_results)
    install_eks(driver, IMAGE_DIR, test_results)
    unity_management_setup(driver, IMAGE_DIR, test_results, "unity-cs-selenium-name", "name")
    unity_management_setup(driver, IMAGE_DIR, test_results, "main", "branch")
    click_button(driver, IMAGE_DIR, test_results, 'default-btn.next-step.svelte-1pvzwgg')
    click_button(driver, IMAGE_DIR, test_results, 'default-btn.next-step.svelte-1pvzwgg')
    click_button(driver, IMAGE_DIR, test_results, 'default-btn.next-step.svelte-1pvzwgg')
    click_button(driver, IMAGE_DIR, test_results, 'btn.btn-primary.svelte-1pvzwgg')
    grab_terminal_output(driver, ".terminal", test_results)

    # Print the results in a table
    print_table(test_results)
    
    # Quit the driver after the test
    driver.quit()
