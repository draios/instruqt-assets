import argparse
import re
import sys
import json
import requests
import time
import urllib3
import logging
# from datetime import datetime


def sysdig_request(method,
                   url,
                   headers,
                   params=None,
                   _json=None,
                   max_retries=5,
                   base_delay=5,
                   max_delay=60,
                   timeout=30,
                   allowed_errors=None,
                   verify_ssl=True):
    """
    Requests data from Sysdig, retried if experiencing transient failures or 429 backoff
    :param verify_ssl: Verify SSL certificate or not, defaults to true but can be oveerriden
    :param method: GET / POST / PUT / DELETE for example
    :param url: URL to query
    :param headers: Headers to pass (authorization for example)
    :param params: Parameters to pass
    :param _json: JSON body (if any)
    :param max_retries: Maximum number of retries
    :param base_delay: base delay
    :param max_delay: max delay
    :param timeout: timeout
    :param allowed_errors: If an allowed erorr, spsecify here (eg, continue on 500)
    :return:
    """
    retries = 0
    e = None  # Initialize e to None

    while retries <= max_retries:
        try:
            urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
            http_response = requests.request(method=method,
                                             url=url,
                                             headers=headers,
                                             params=params,
                                             json=_json,
                                             timeout=timeout,
                                             verify=verify_ssl)
            # If response is successful, or contains an acceptable error message, return it
            if http_response.ok or (allowed_errors and any(msg in http_response.text for msg in allowed_errors)):
                if allowed_errors and any(msg in http_response.text for msg in allowed_errors):
                    logging.info(f"sysdig_request:: Allowed error, Continuing...")
                return http_response
            http_response.raise_for_status()
        except requests.exceptions.RequestException as ex:
            e = ex  # Update e with the caught exception
            delay = min(base_delay * (2 ** retries), max_delay)

            # Check if the error message is acceptable when response is available
            if allowed_errors and e.response:
                try:
                    response_body = e.response.text
                    if any(msg in response_body for msg in allowed_errors):
                        logging.info(f"sysdig_request:: Allowed error, Continuing...")
                        return e.response
                except Exception as ex_inner:
                    logging.fatal(f"sysdig_request:: Error while processing response body: {ex_inner}")

            logging.warning(f"sysdig_request:: Error {e}, Retrying in {delay} seconds...")
            logging.warning(f"sysdig_request:: Retry {retries}, Sleeping for {delay} seconds")
            time.sleep(delay)
            retries += 1

    print(" ERROR ".center(80, "-"))
    logging.warning(f"sysdig_request:: Failed to fetch data from {url} after {max_retries} retries.")
    if e:
        logging.warning(f"sysdig_request:: Error making request to {url}: {e}")
    else:
        logging.warning(f"sysdig_request"" An unexpected error occurred making request to {url}")

    http_response = requests.Response()
    http_response.status_code = 503  # Service is unavailable
    http_response._content = b"Service is unavailable after retries."
    return http_response


def parse_arguments():
    """
    Parses argument entered on command line and valides against custom logic
    :return:
    """
    parser = argparse.ArgumentParser(description="Sysdig Add User and Team Scope Utility")
    operation_group = parser.add_mutually_exclusive_group(required=True)

    operation_group.add_argument('--add', action='store_true')
    operation_group.add_argument('--delete', action='store_true')
    operation_group.add_argument('--update', action='store_true')

    # Add arguments similar to bash script
    parser.add_argument('--apitoken', required=True, help="API token")
    parser.add_argument('--firstname', required="--add" in sys.argv,  help="User firstname")
    parser.add_argument('--lastname', required="--add" in sys.argv, help="User Lastname")
    parser.add_argument('--email', required="--add" in sys.argv,  help="User Emailaddress")
    parser.add_argument('--secure', required=False, action='store_true', help="Create user for Secure")
    parser.add_argument('--monitor', required=False, action='store_true', help="Create user for Monitor")
    parser.add_argument('--region', required=True in sys.argv, help="Region to create in")
    parser.add_argument('--debug', required="--add" in sys.argv, action='store_true', help="Debug mode")
    parser.add_argument('--isadmin', required=False, action='store_true', help="Admin user")
    parser.add_argument('--clustername', required="--add" in sys.argv, help="Kubernetes cluster name")

    parser.add_argument('--userid', required=["--delete", "--update"] in sys.argv, help="Userid to update/delete")

    parser.add_argument('--teamid', required="--delete" in sys.argv, help="Teamid to delete")
    parser.add_argument('--zoneid', required="--delete" in sys.argv, help="Zoneid to delete")

    args = parser.parse_args()

    logging.basicConfig(level="DEBUG" if args else "INFO",
                        format='%(asctime)s - %(levelname)s - %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')

    args.auth_header = {
        "Authorization": f"Bearer {args.apitoken}",
        "Content-Type": "application/json;charset=UTF-8"
        }

    # Validate and set additional flags or perform other actions based on arguments
    validate_arguments(args)

    return args


def validate_arguments(args):
    """
    Validation logic for command line arguments
    :param args:
    :return:
    """
    # Add your validation logic here
    # Example: Validating the Sysdig API Token format
    token_pattern = re.compile(r'^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}}?$')
    if not token_pattern.match(args.apitoken):
        logging.fatal("validate_arguments:: Error: Please provide a valid Sysdig API Token.")
        sys.exit(2)

    logging.debug(f"validate_arguments:: Argument: apitoken: {args.apitoken}")
    logging.debug(f"validate_arguments:: Argument: firstname: {args.firstname}")
    logging.debug(f"validate_arguments:: Argument: lastname: {args.lastname}")
    logging.debug(f"validate_arguments:: Argument: email: {args.email}")
    logging.debug(f"validate_arguments:: Argument: secure: {args.secure}")
    logging.debug(f"validate_arguments:: Argument: monitor: {args.monitor}")
    logging.debug(f"validate_arguments:: Argument: isadmin: {args.isadmin}")
    logging.debug(f"validate_arguments:: Argument: clustername: {args.clustername}")


def create_user(_args, _zoneid, _clustername):
    url = f"https://api.{_args.region}.sysdig.com/platform/v1/users"
    payload = {
        "email": _args.email,
        "firstName": _args.firstname,
        "isAdmin": _args.isadmin,
        "lastName": _args.lastname,
        "products": (["secure"] if _args.secure else []) +
                    (["monitor"] if _args.monitor else [])
    }

    logging.info("")
    logging.debug(f"create_user:: Creating User: firstname={_args.firstname}")
    logging.debug(f"create_user:: Creating User: lastname={_args.lastname}")
    logging.debug(f"create_user:: Creating User: email={_args.email}")
    logging.debug(f"create_user:: Creating User: secure={_args.secure}")
    logging.debug(f"create_user:: Creating User: monitor={_args.monitor}")
    logging.debug(f"create_user:: Creating User: isadmin={_args.isadmin}")
    logging.debug(f"create_user:: Creating User: payload={json.dumps(payload, indent=4)}")

    response = sysdig_request(method="POST",
                              url=url,
                              _json=payload,
                              verify_ssl=False,
                              headers=_args.auth_header,
                              max_retries=1)

    response_json = response.json()
    if response.status_code == 201:
        logging.info(f"create_user:: Added User: {_args.email}")
        logging.debug(f"create_user:: response: {json.dumps(response.json(), indent=4)}")
        return True, response_json['id']
    else:
        logging.error(f"create_team:: response: {json.dumps(response_json, indent=4)}")
        return False, 0


def create_team_old(_args, _zoneid, _userid):
    if _args.region in ['au1', 'me1', 'us4']:
        url = f"https://app.{_args.region}.sysdig.com/api/teams"
    else:
        url = f"https://{_args.region}.app.sysdig.com/api/teams"

    payload = {
        "userRoles": [
            {
                "role": "ROLE_TEAM_EDIT",
                "userId": int(_userid),
            }
        ],
        "id": None,
        "name": f"{_args.clustername} Team",
        "theme": "#73A1F7",
        "defaultTeamRole": "ROLE_TEAM_EDIT",
        "description": f"{_args.clustername} Team Description",
        "show": "container",
        "searchFilter": None,
        "default": False,
        "immutable": False,
        "filter": f"kubernetes.cluster.name = \"{_args.clustername}\" and kubernetes.namespace.name = \"default\"",
        "namespaceFilters": {
            "prometheusRemoteWrite": None
        },
        "canUseRapidResponse": False,
        "canUseSysdigCapture": False,
        "canUseAgentCli": False,
        "canUseCustomEvents": False,
        "canUseAwsMetrics": False,
        "canUseBeaconMetrics": False,
        "products": None,
        "origin": "SYSDIG",
        "entryPoint": {
            "module": "Overview"
        },
        "zoneIds": [
            int(_zoneid)
        ],
        "allZones": False
    }

    logging.debug(f"create_team:: Creating Team: payload={json.dumps(payload, indent=4)}")
    response = sysdig_request(method="POST",
                              url=url,
                              _json=payload,
                              verify_ssl=False,
                              headers=_args.auth_header,
                              max_retries=1)

    response_json = response.json()
    if response.status_code == 201:
        logging.info(f"create_team:: Created Team: {_args.clustername}")
        logging.debug(f"create_team:: response: {json.dumps(response_json, indent=4)}")
        return True, response_json['team']['id']
    else:
        logging.error(f"create_team:: response: {json.dumps(response_json, indent=4)}")
        return False, 0


def create_team_new(_args, _zoneid, _clustername):
    url = f"https://api.{_args.region}.sysdig.com/platform/v1/teams"
    payload = {
        "additionalTeamPermissions": {
            "hasAgentCli": None,
            "hasAwsData": None,
            "hasInfrastructureEvents": None,
            "hasRapidResponse": None,
            "hasSysdigCaptures": None
        },
        "customTeamRoleId": None,
        "description": f"{_args.clustername} team description",
        "isAllZones": False,
        "isDefaultTeam": False,
        "name": f"{_clustername} Team",
        "product": "secure",
        "scopes": [
            {
                "type": "HOST_CONTAINER",
                "expression": "container"
            },
            {
                "type": "AGENT",
                "expression": f"kubernetes.cluster.name in (\"{_args.clustername}\")"
            },
            {
                "type": "PROMETHEUS_REMOTE_WRITE",
                "expression": None
            }
        ],
        "standardTeamRole": "ROLE_TEAM_EDIT",
        "zoneIds": [
            _zoneid
        ]
    }
    logging.debug(f"create_team:: Creating Team: payload={json.dumps(payload, indent=4)}")
    response = sysdig_request(method="POST",
                              url=url,
                              _json=payload,
                              verify_ssl=False,
                              headers=_args.auth_header,
                              max_retries=1)

    response_json = response.json()
    if response.status_code == 201:
        logging.info(f"create_team:: Created Team: {_args.clustername}")
        logging.debug(f"create_team:: response: {json.dumps(response_json, indent=4)}")
        return True, response_json['id']
    else:
        logging.error(f"create_team:: response: {json.dumps(response_json, indent=4)}")
        return False, 0


def create_zone(_args):
    if _args.region in ['au1', 'me1', 'us4']:
        url = f"https://app.{_args.region}.sysdig.com/api/cspm/v1/policy/zones"
    else:
        url = f"https://{_args.region}.app.sysdig.com/api/cspm/v1/policy/zones"

    payload = {
        "name": _args.clustername,
        "description": f"{_args.clustername} Zone",
        "scopes": [
            {"rules": f"clusterId in (\"{_args.clustername}\")",
             "targetType": "kubernetes"}
        ],
        "policyIds": [],
        "id": "0"
    }
    logging.debug(f"create_zone:: Payload: {json.dumps(payload, indent=4)}")

    response = sysdig_request(method="POST",
                              url=url,
                              _json=payload,
                              verify_ssl=False,
                              headers=_args.auth_header,
                              max_retries=1)

    response_json = response.json()
    if response.status_code == 200:
        logging.info(f"create_zone:: Created Zone: {_args.clustername}")
        logging.debug(f"create_zone:: response: {json.dumps(response_json, indent=4)}")
        return True, response_json['data']['id']
    else:
        logging.error(f"create_zone:: response: {json.dumps(response_json, indent=4)}")
        return False, 0


def delete_zone(_args):
    if _args.region in ['au1', 'me1', 'us4']:
        url = f"https://app.{_args.region}.sysdig.com/api/cspm/v1/policy/zones/{_args.zoneid}"
    else:
        url = (f"https://{_args.region}.app."
               f"sysdig.com/api/cspm/v1/policy/zones/{_args.zoneid}")

    response = sysdig_request(method="DELETE",
                              url=url,
                              verify_ssl=False,
                              headers=_args.auth_header,
                              max_retries=1)

    if response.status_code == 204:
        logging.info(f"delete_team:: Deleted zone: {_args.zoneid}")
        return True
    else:
        logging.error(f"delete_team:: Failed to delete zone: {_args.zoneid}")
        return False


def delete_team(_args):
    url = f"https://api.{_args.region}.sysdig.com/platform/v1/teams/{_args.teamid}"

    response = sysdig_request(method="DELETE",
                              url=url,
                              verify_ssl=False,
                              headers=_args.auth_header,
                              max_retries=1)

    if response.status_code == 204:
        logging.info(f"delete_team:: Deleted team: {_args.teamid}")
        return True
    else:
        logging.error(f"delete_team:: Failed to delete team: {_args.teamid}")
        return False


def delete_user(_args):
    url = f"https://api.{_args.region}.sysdig.com/platform/v1/users/{_args.userid}"

    response = sysdig_request(method="DELETE",
                              url=url,
                              verify_ssl=False,
                              headers=_args.auth_header,
                              max_retries=1)

    if response.status_code == 204:
        logging.info(f"delete_user:: Deleted User: {_args.userid}")
        return True
    else:
        logging.error(f"delete_user:: Failed to delete User: {_args.userid}")
        return False


def update_user(_args, _teamid, _userid):
    url = f"https://api.{_args.region}.sysdig.com/platform/v1/teams/{_teamid}/users/{_userid}"
    payload = {
        "standardTeamRole": "ROLE_TEAM_EDIT"
    }
    response = sysdig_request(method="PUT",
                              url=url,
                              _json=payload,
                              verify_ssl=False,
                              headers=_args.auth_header,
                              max_retries=1)

    response_json = process_api_response(response)
    if response.status_code == 201 and response_json is not None:
        logging.info(f"update_user:: Updated User: {_userid}")
        logging.debug(f"update_user:: response: {json.dumps(response_json, indent=4)}")
        return True
    else:
        logging.error(f"update_user:: response: {json.dumps(response_json, indent=4)}")
        return False


def process_api_response(response):
    """
    Process the API response.

    :param response: The response object to process.
    :return: A tuple containing the status code and the parsed JSON content (or None if not applicable).
    """
    # Check if the response was successful
    if response.ok:
        # Attempt to parse JSON content
        try:
            json_content = response.json()
            return json_content
        except ValueError:
            # Handle JSON parsing errors
            print("Response content is not valid JSON.")
    else:
        print("Request failed with status code:", response.status_code)

    return None


def delete_default_team_memberships(_args, _userid):
    get_url = f"https://api.{_args.region}.sysdig.com/platform/v1/teams"

    response = sysdig_request(method="GET",
                              url=get_url,
                              verify_ssl=False,
                              headers=_args.auth_header,
                              max_retries=1)

    response_json = process_api_response(response)

    if response.status_code == 200 and response_json is not None:
        length = len(response_json['data'])-1
        for index, item in enumerate(response_json['data']):
            logging.debug(f"delete_default_team_memberships:: Processing team {index}/{length}: {item['name']}")
            if item['isDefaultTeam']:
                logging.info(f"delete_default_team_memberships:: Deleting userid {_userid} from team {item['name']}")
                delete_url = f"https://api.{_args.region}.sysdig.com/platform/v1/teams/{item['id']}/users/{_userid}"
                response = sysdig_request(method="DELETE",
                                          url=delete_url,
                                          verify_ssl=False,
                                          headers=_args.auth_header,
                                          max_retries=1,
                                          allowed_errors="Not Found")
                if response.status_code == 204:
                    logging.info(f"delete_default_team_memberships:: Membership Deleted")


def main():
    """
    Main function for processing, called by entrypoint
    :return:
    """

    args = parse_arguments()
    if args.add or args.update:
        # Now that arguments are validated, add user
        zone_status, zoneid = create_zone(_args=args)
        if zone_status:
            if args.add:
                user_status, userid = create_user(_args=args,
                                                  _zoneid=zoneid,
                                                  _clustername=args.clustername)
            else:  # is hence update
                userid = args.userid
                user_status = True
            if user_status:
                team_status, teamid = create_team_old(_args=args,
                                                      _zoneid=zoneid,
                                                      _userid=userid)

                delete_default_team_memberships(_args=args,
                                                _userid=userid)
                with open('/opt/sysdig/userid', "w") as file:
                    file.write(str(userid))
                with open('/opt/sysdig/teamid', "w") as file:
                    file.write(str(teamid))
                with open('/opt/sysdig/zoneid', "w") as file:
                    file.write(str(zoneid))

    if args.delete:
        delete_zone(_args=args)
        delete_team(_args=args)
        # delete_user(_args=args)


if __name__ == "__main__":
    """
    Main entrypoint.
    """
    main()
