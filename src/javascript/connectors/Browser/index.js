import { LiaDB } from './database'
//import { SETTINGS, initSettings } from './settings'

class Connector {
  constructor (send = null) {
    this.hasIndex = true

    //this.settings = initSettings()
  }

  connect(send = null) {
    this.database = new LiaDB(send)
  }

  open(uidDB, versionDB, slide) {
    this.database.open(
      uidDB,
      versionDB,
      { topic: 'code',
        section: slide,
        message: {
          topic: 'restore',
          section: -1,
          message: null }
    })
  }

  load(event) {
    this.database.load(event)
  }

  store(event) {
    this.database.store(event)
  }

  update(event, id) {
    this.database.update(event, id)
  }

  slide(id) {
    this.database.slide(id)
  }

  getIndex() {
    this.database.listIndex()
  }

  deleteFromIndex(msg) {
    this.database.deleteIndex(msg)
  }

  storeToIndex(json) {
    this.database.storeIndex(json)
  }

  restoreFromIndex(uidDB, versionDB = null) {
    this.database.restore(uidBD, versionDB)
  }

  reset(uidDB, versionDB = null) {
    this.database.reset(uidDB, versionDB)
  }

  getFromIndex(uidDB) {
    this.database.getIndex(uidDB)
  }
}

export { Connector }
