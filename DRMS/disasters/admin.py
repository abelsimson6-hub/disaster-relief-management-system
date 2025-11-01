from django.contrib import admin
from .models import Disasters

@admin.register(Disasters)
class DisastersAdmin(admin.ModelAdmin):
    list_display = (
        'id', 'name', 'disaster_type', 'severity', 
        'status', 'location', 'start_date', 'end_date'
    )
    list_filter = ('disaster_type', 'severity', 'status', 'start_date')
    search_fields = ('name', 'location', 'description', 'affected_areas')
    ordering = ('-start_date',)
    readonly_fields = ('created_at', 'updated_at')

    fieldsets = (
        ('General Information', {
            'fields': ('name', 'disaster_type', 'severity', 'status', 'description')
        }),
        ('Location Details', {
            'fields': ('location', 'latitude', 'longitude', 'affected_areas')
        }),
        ('Timeline', {
            'fields': ('start_date', 'end_date')
        }),
        ('Impact & Metadata', {
            'fields': ('estimated_damage', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
