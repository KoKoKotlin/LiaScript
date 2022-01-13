import * as Beaker from '../../sync/Beaker/index'
import * as Jitsi from '../../sync/Jitsi/index'
import * as Matrix from '../../sync/Matrix/index'
import * as PubNub from '../../sync/PubNub/index'
import * as GUN from '../../sync/Gun/index'

import log from '../log'

var sync: any

const Service = {
  PORT: 'sync',

  supported: function (allowSync: boolean) {
    return allowSync
      ? [
          // beaker is only supported within the beaker-browser
          Beaker.isSupported() ? 'beaker' : '',
          // remove these strings if you want to enable or disable certain sync support
          'gun',
          'jitsi',
          'matrix',
          'pubnub',
        ]
      : []
  },

  handle: function (elmSend: any, event: Lia.Event) {
    switch (event.message.cmd) {
      case 'connect': {
        if (sync) sync = undefined

        switch (event.message.param.backend) {
          case 'beaker':
            sync = new Beaker.Sync(elmSend)
            break

          case 'gun':
            sync = new GUN.Sync(elmSend)
            break

          case 'jitsi':
            sync = new Jitsi.Sync(elmSend)
            break

          case 'matrix':
            sync = new Matrix.Sync(elmSend)
            break

          case 'pubnub':
            sync = new PubNub.Sync(elmSend)
            break

          default:
            log.error('could not load =>', event.message)
        }

        if (sync) sync.connect(event.message.param.config)

        break
      }

      case 'disconnect': {
        if (sync) sync.disconnect()
        break
      }

      default: {
        if (sync) {
          sync.publish(event)
        } else {
          log.warn('(Service Sync) unknown message =>', event.message)
        }
      }
    }
  },
}

export default Service