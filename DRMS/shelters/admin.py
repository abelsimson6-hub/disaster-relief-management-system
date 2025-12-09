from django.contrib import admin
from .models import Camp

@admin.register(Camp)
class CampAdmin(admin.ModelAdmin):
    # Columns to display in the list view
    list_display = ('name', 'camp_type', 'disasters', 'location', 'capacity', 'status', 'contact_person', 'contact_phone')
    
    # Fields that can be used to filter the list
    list_filter = ('camp_type', 'status', 'disasters')
    
    # Fields that can be searched
    search_fields = ('name', 'location', 'contact_person', 'contact_phone', 'email')
    
    # Fields that are read-only
    readonly_fields = ('created_at', 'updated_at')
    
    # Ordering of the list view
    ordering = ('name',)

    # Optional: grouping fields in the admin form
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'camp_type', 'disasters', 'status')
        }),
        ('Location & Capacity', {
            'fields': ('location', 'latitude', 'longitude', 'capacity')
        }),
        ('Contact Information', {
            'fields': ('contact_person', 'contact_phone', 'email')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )
