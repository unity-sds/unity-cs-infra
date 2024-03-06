import boto3
import re

# Predefined list of required tag that should be present on all resources
TAG_KEYS = ["Venue", "ServiceArea", "CapVersion", "Component", "Name", "Proj", "CreatedBy", "Env", "Stack"]

# Patterns for identifying groups and their corresponding labels
TAG_KEY_PATTERN_LABELS = [
    # This tuple contains a regex pattern to match against resource ARNs and a label for the category
     ("ucs|hargitay|galen|ryan|tom|hollins|ramesh|rmaddego|molen|apigw|apigateway", "U-CS"),
     ("uds|cumulus", "U-DS"),
    ("uads|jmcduffi|dockstore|esarkiss|nlahaye|jupyter", "U-ADS"),
    ("usps|u-sps|sps-api|luca|ryan|hysds", "U-SPS"),
    ("bcdp", "U-AS"),
    ("gmanipon|on-demand", "U-OD"),
    ("anil|tapella|natha", "U-UI")

# Additional patterns can be uncommented/added here to extend the functionality
]


def get_resources():
    # Create a boto3 client for accessing AWS Resource Groups Tagging API
    client = boto3.client('resourcegroupstaggingapi', region_name='us-west-2')
    paginator = client.get_paginator('get_resources')
    resources = []
    # Collect all resources across all pages from the paginator
    for page in paginator.paginate():
        resources.extend(page['ResourceTagMappingList'])
    return resources

def filter_untagged_resources_by_pattern(pattern):
    # Retrieve all resources
    resources = get_resources()
    untagged_resources = []
    # Iterate through each resource to check if it matches the pattern and lacks required tags
    for resource in resources:
        if re.search(pattern, resource['ResourceARN']):
            tagged_keys = {tag['Key'] for tag in resource['Tags']}
            # Check if the resource lacks any of the required tags
            if not set(TAG_KEYS).intersection(tagged_keys):
                untagged_resources.append(resource['ResourceARN'])
    return untagged_resources

def print_untagged_resource_details():
    print("-------------------------------------------------")
    print("Untagged Resources by Category")
    print("-------------------------------------------------")
    
    # Iterate through each pattern/label tuple to find and print untagged resources by category
    for pattern, label in TAG_KEY_PATTERN_LABELS:
        untagged_resources = filter_untagged_resources_by_pattern(pattern)
        print(f"CATEGORY    : {label}")
        print(f"SEARCH USED : {pattern}")
        print("-------------------------------------------------")
        if untagged_resources:
            for arn in untagged_resources:
                print(f"- {arn}")
        else:
            print("No untagged resources found in this category.")
        print("-------------------------------------------------")

if __name__ == "__main__":
    print_untagged_resource_details()

