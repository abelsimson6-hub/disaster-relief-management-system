"""from django.contrib import admin
from .models import User, Volunteer, Victim
admin.site.register(User)
admin.site.register(Volunteer)
admin.site.register(Victim)"""

from django.contrib import admin
from .models import User

# Register your custom user model
@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('username', 'email', 'role', 'is_staff', 'is_active')
    list_filter = ('role', 'is_staff', 'is_active')
    search_fields = ('username', 'email')
    ordering = ('username',)
