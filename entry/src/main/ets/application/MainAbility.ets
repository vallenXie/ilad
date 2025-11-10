import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import Logger from '../common/Logger';

export default class MainAbility extends UIAbility {
  onCreate(want: any, launchParam: any): void {
    Logger.info('MainAbility onCreate');
  }

  onDestroy(): void {
    Logger.info('MainAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info('MainAbility onWindowStageCreate start');
    windowStage.loadContent('pages/Index', (err, _data) => {
      if (err.code) {
        Logger.error(`Failed to load content. Code: ${err.code}, message: ${err.message}`);
        return;
      }
      Logger.info('MainAbility onWindowStageCreate success');
    });
  }

  onWindowStageDestroy(): void {
    Logger.info('MainAbility onWindowStageDestroy');
  }
}
