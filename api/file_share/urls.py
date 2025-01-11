from django.urls import path
from file_share.views import *

urlpatterns = [
    path("", index),
    path("signup/", signup),
    path("login/", login),
    path("check-code/", check_code),
    path("get-devices/", get_devices),
    path("modify-device/", modify_device),
    path("get-contacts/", get_contacts),
    path("add-contact/", add_contact),
    path("modify-contact/", modify_contact)
]