from .material_master_seeder import seed_material_masters
from .material_standard_seeder import seed_material_standards
from .user_seeder import seed_admin_user

SEEDERS = {
    "admin-user": seed_admin_user,
    "material-masters": seed_material_masters,
    "material-standards": seed_material_standards,
}


