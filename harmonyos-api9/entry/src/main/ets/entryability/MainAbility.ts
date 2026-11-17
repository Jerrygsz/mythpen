import UIAbility from '@ohos.app.ability.UIAbility'
import window from '@ohos.window'

export default class MainAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage) {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        console.error('Failed to load page: ' + JSON.stringify(err))
      }
    })
  }
}
