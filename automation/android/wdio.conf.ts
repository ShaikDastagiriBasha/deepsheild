export const config: WebdriverIO.Config = {
    runner: 'local',
    port: 4723,
    path: '/',
    specs: [
        './tests/**/*.ts'
    ],
    maxInstances: 1,
    capabilities: [{
        platformName: 'Android',
        'appium:deviceName': 'Android Emulator',
        'appium:app': '../../build/app/outputs/flutter-apk/app-debug.apk',
        'appium:automationName': 'UiAutomator2',
        'appium:autoGrantPermissions': true
    }],
    logLevel: 'info',
    waitforTimeout: 10000,
    connectionRetryTimeout: 120000,
    connectionRetryCount: 3,
    framework: 'mocha',
    reporters: ['spec'],
    mochaOpts: {
        ui: 'bdd',
        timeout: 60000
    },
}
