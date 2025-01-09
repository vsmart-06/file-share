from django.urls import path
from file_share.views import *

urlpatterns = [
    path("", index),
    path("signup/", signup),
    path("login/", login),
    path("check-code/", check_code)
]