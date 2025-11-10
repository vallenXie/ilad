import { appTask, harTask } from '@ohos/hvigor-ohos-plugin';

export default {
  system: appTask,
  modules: [
    harTask('entry')
  ]
};
