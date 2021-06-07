from requests import get
from re import sub
from http import HTTPStatus

METADATA_URI = 'http://metadata.google.internal/computeMetadata/v1/instance'


def get_zone():
    """Gets the GCE zone of this instance.
    Returns:
        str: The name of the zone if the zone was successfully determined.
        Empty string otherwise.
    """
    try:
        r = get(f"{METADATA_URI}/zone", headers={'Metadata-Flavor': 'Google'})
        if r.status_code == HTTPStatus.OK:
            return sub(r'.+zones/(.+)', r'\1', r.text), None
        else:
            return '', r.reason
    except Exception as ex:
        return '', ex


def get_template():
    """Gets the GCE instance template of this instance.
    Returns:
        str: The name of the template if the template was successfully
        determined and this instance was built using an instance template.
        Empty string otherwise.
    """
    try:
        r = get(f'{METADATA_URI}/attributes/instance-template', headers={'Metadata-Flavor': 'Google'})
        if r.status_code == HTTPStatus.OK:
            return sub(r'.+instanceTemplates/(.+)', r'\1', r.text), None
        else:
            return '', r.reason
    except Exception as ex:
        return '', ex
