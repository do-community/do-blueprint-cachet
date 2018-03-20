<?php

/*
 * This file is part of Cachet.
 *
 * (c) Alt Three Services Limited
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

namespace CachetHQ\Cachet\Console;

use CachetHQ\Cachet\Console\Commands\DemoMetricPointSeederCommand;
use CachetHQ\Cachet\Console\Commands\DemoSeederCommand;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * The Artisan commands provided by your application.
     *
     * @var array
     */
    protected $commands = [
        DemoMetricPointSeederCommand::class,
        DemoSeederCommand::class,
    ];

    /**
     * Define the application's command schedule.
     *
     * @param \Illuminate\Console\Scheduling\Schedule $schedule
     *
     * @return void
     */
    protected function schedule(Schedule $schedule)
    {
        $schedule->command('queue:work --sleep=3 --tries=3')->everyMinute();
        $schedule->command('backup:clean')->daily()->at('01:43');
        $schedule->command('backup:run')->daily()->at('02:24');
        $schedule->command('backup:monitor')->daily()->at('05:19');
    }
}
