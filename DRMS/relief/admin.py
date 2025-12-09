from django.contrib import admin
from .models import Resource, ResourceRequest

@admin.register(Resource)
class ResourceAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'unit', 'is_active', 'created_at')
    list_filter = ('category', 'is_active', 'unit')
    search_fields = ('name', 'description')
    ordering = ('name',)

@admin.register(ResourceRequest)
class ResourceRequestAdmin(admin.ModelAdmin):
    list_display = ('resource', 'camp', 'quantity_requested', 'quantity_fulfilled', 'priority', 'status', 'request_date', 'needed_by')
    list_filter = ('priority', 'status', 'camp')
    search_fields = ('resource__name', 'camp__name', 'requested_by__username', 'reason')
    ordering = ('-request_date',)
