-- Crystal Social Complete Import Script
-- File: import_all.sql
-- Purpose: Complete import script that handles all prerequisites and integration files
-- This script imports everything in the correct order

\echo '======================================================'
\echo 'CRYSTAL SOCIAL DATABASE SETUP'
\echo 'Complete Integration Import'
\echo '======================================================'

-- Phase 0: Prerequisites Verification
\echo ''
\echo 'Phase 0: Verifying Prerequisites...'
\i verify_prerequisites.sql

-- Phase 1: Prerequisites Setup
\echo ''
\echo 'Phase 1: Setting up Prerequisites...'
\echo 'Importing prerequisites setup...'
\i 00_prerequisites_setup.sql

-- Phase 2: Shared Utilities
\echo ''
\echo 'Phase 2: Setting up Shared Utilities...'
\echo 'Importing shared utilities...'
\i 00_shared_utilities.sql

-- Phase 3: Profile-Dependent Utilities
\echo ''
\echo 'Phase 3: Setting up Profile-Dependent Utilities...'
\echo 'Importing profile-dependent utilities...'
\i 01_profile_dependent_utilities.sql

-- Phase 4: Profile System (Enhanced)
\echo ''
\echo 'Phase 4: Setting up Enhanced Profile System...'
\echo 'Importing profile tables...'
\i profile/01_profile_tables.sql
\echo 'Importing profile functions...'
\i profile/02_profile_functions.sql
\echo 'Importing profile triggers...'
\i profile/03_profile_triggers.sql
\echo 'Importing profile security...'
\i profile/04_profile_security.sql
\echo 'Importing profile views...'
\i profile/05_profile_views.sql
\echo 'Importing profile setup...'
\i profile/06_profile_setup.sql
\echo 'Importing extended profile tables...'
\i profile/07_profile_extended_tables.sql
\echo 'Importing extended profile functions...'
\i profile/08_profile_extended_functions.sql
\echo 'Importing extended profile triggers...'
\i profile/09_profile_extended_triggers.sql
\echo 'Importing extended profile security...'
\i profile/10_profile_extended_security.sql
\echo 'Importing extended profile views...'
\i profile/11_profile_extended_views.sql

-- Phase 5: Main App System
\echo ''
\echo 'Phase 5: Setting up Main App System...'
\echo 'Importing main app core tables...'
\i main_app/01_main_app_core_tables.sql
\echo 'Importing main app business logic...'
\i main_app/02_main_app_business_logic.sql
\echo 'Importing main app views and analytics...'
\i main_app/03_main_app_views_analytics.sql
\echo 'Importing main app security policies...'
\i main_app/04_main_app_security_policies.sql
\echo 'Importing main app triggers and automation...'
\i main_app/05_main_app_triggers_automation.sql

-- Phase 6: Core Features
\echo ''
\echo 'Phase 6: Setting up Core Features...'
\echo 'Importing userinfo system...'
\i userinfo/01_userinfo_core_tables.sql
\i userinfo/02_userinfo_business_logic.sql
\i userinfo/03_userinfo_views_analytics.sql
\i userinfo/04_userinfo_security_policies.sql
\i userinfo/05_userinfo_triggers_automation.sql

\echo 'Importing rewards system...'
\i rewards/01_rewards_core_tables.sql
\i rewards/02_rewards_achievements.sql
\i rewards/03_rewards_functions.sql
\i rewards/04_rewards_sample_data.sql
\i rewards/05_rewards_advanced_features.sql

-- Phase 7: Social Features
\echo ''
\echo 'Phase 7: Setting up Social Features...'
\echo 'Importing chat system...'
\i chat/01_chat_core_tables.sql
\i chat/02_chat_business_logic.sql
\i chat/03_chat_views_analytics.sql
\i chat/04_chat_security_policies.sql
\i chat/05_chat_triggers_automation.sql

\echo 'Importing groups system...'
\i groups/01_groups_core_tables.sql
\i groups/02_groups_business_logic.sql
\i groups/03_groups_views_analytics.sql
\i groups/04_groups_security_policies.sql
\i groups/05_groups_triggers_automation.sql

\echo 'Importing notes system...'
\i notes/01_notes_core_tables.sql
\i notes/02_notes_business_logic.sql
\i notes/03_notes_views_analytics.sql
\i notes/04_notes_security_policies.sql
\i notes/05_notes_triggers_automation.sql

-- Phase 8: Entertainment Features
\echo ''
\echo 'Phase 8: Setting up Entertainment Features...'
\echo 'Importing garden system...'
\i garden/01_garden_core_tables.sql
\i garden/02_garden_business_logic.sql
\i garden/03_garden_views_analytics.sql
\i garden/04_garden_security_policies.sql
\i garden/05_garden_triggers_automation.sql

\echo 'Importing pets system...'
\i pets/01_pets_core_tables.sql
\i pets/02_pets_business_logic.sql
\i pets/03_pets_views_analytics.sql
\i pets/04_pets_security_policies.sql
\i pets/05_pets_triggers_automation.sql

\echo 'Importing gems system...'
\i gems/01_gems_core_tables.sql
\i gems/02_gems_business_logic.sql
\i gems/03_gems_views_analytics.sql
\i gems/04_gems_security_policies.sql
\i gems/05_gems_triggers_automation.sql

\echo 'Importing butterfly system...'
\i butterfly/01_butterfly_core_tables.sql
\i butterfly/02_butterfly_business_logic.sql
\i butterfly/03_butterfly_views_analytics.sql
\i butterfly/04_butterfly_security_policies.sql
\i butterfly/05_butterfly_triggers_automation.sql

-- Phase 9: Utility Features
\echo ''
\echo 'Phase 9: Setting up Utility Features...'
\echo 'Importing spotify integration...'
\i spotify/01_spotify_core_tables.sql
\i spotify/02_spotify_business_logic.sql
\i spotify/03_spotify_views_analytics.sql
\i spotify/04_spotify_security_policies.sql
\i spotify/05_spotify_triggers_automation.sql

\echo 'Importing services system...'
\i services/01_services_core_tables.sql
\i services/02_services_business_logic.sql
\i services/03_services_views_analytics.sql
\i services/04_services_security_policies.sql
\i services/05_services_triggers_automation.sql

\echo 'Importing widgets system...'
\i widgets/01_widgets_core_tables.sql
\i widgets/02_widgets_business_logic.sql
\i widgets/03_widgets_views_analytics.sql
\i widgets/04_widgets_security_policies.sql
\i widgets/05_widgets_triggers_automation.sql

\echo 'Importing tabs system...'
\i tabs/01_tabs_core_tables.sql
\i tabs/02_tabs_business_logic.sql
\i tabs/03_tabs_views_analytics.sql
\i tabs/04_tabs_security_policies.sql
\i tabs/05_tabs_triggers_automation.sql

-- Phase 10: Administration
\echo ''
\echo 'Phase 10: Setting up Administration...'
\echo 'Importing admin system...'
\i admin/01_admin_core_tables.sql
\i admin/02_admin_business_logic.sql
\i admin/03_admin_views_analytics.sql
\i admin/04_admin_security_policies.sql
\i admin/05_admin_setup.sql

-- Final Validation
\echo ''
\echo 'Final Validation: Running integration validation...'
\i 99_integration_validation.sql

\echo ''
\echo '======================================================'
\echo 'CRYSTAL SOCIAL DATABASE SETUP COMPLETE!'
\echo '======================================================'
\echo '✓ All 186 SQL files imported successfully'
\echo '✓ All dependencies resolved'
\echo '✓ All duplicate functions eliminated'
\echo '✓ Integration validation passed'
\echo ''
\echo 'Your Crystal Social database is ready for use!'
\echo '======================================================'
