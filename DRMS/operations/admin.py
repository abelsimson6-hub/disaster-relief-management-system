from django.contrib import admin
from .models import HelpRequest, TaskAssignment
admin.site.register(HelpRequest)
admin.site.register(TaskAssignment)