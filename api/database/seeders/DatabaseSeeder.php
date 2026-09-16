<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Root seeder entrypoint (`php artisan db:seed`, wired to `make seed`).
 *
 * Run order is FK-safe: AdminPanelSeeder owns Organizer/Venue/Event/Promoter/
 * PlanPrice records that WebAppSeeder's Favorite/EventInterest rows reference,
 * so it must run first.
 *
 * NOTE: AdminPanelSeeder (admin-panel/tasks.md T42) and WebAppSeeder
 * (web-app/tasks.md T37) do not exist yet - those features' Execute phases
 * haven't run. This file establishes the run order the real seeders must
 * follow once they land; it will not execute until then.
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            AdminPanelSeeder::class,
            WebAppSeeder::class,
        ]);
    }
}
