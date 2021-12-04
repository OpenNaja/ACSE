package core.managers {
  import flash.events.EventDispatcher;

  public class CommunicationManager extends EventDispatcher {

    public var SetReadyForInvokes: Function = null;

    public var HandleMessage: Function = null;

    public var AddListener: Function = null;

    public var RemoveListener: Function = null;

    public var UIOpened: Function = null;

    public var UIClosed: Function = null;

    public var SendEventToGame: Function = null;

    public var PlaySound: Function = null;

    public var PlayNarration: Function = null;

    public var Translate: Function = null;

    public var GetMovieName: Function = null;

    public var LocaliseNumber: Function = null;

    public var GetDatabaseItemData: Function = null;

    public var Assert: Function = null;

    public var Break: Function = null;

    public var CloseMovie: Function = null;

    public var GetData: Function = null;

    public var DoAction: Function = null;

    public var CapturingButtons: Function = null;

    public var CapturingMouse: Function = null;

    public var LoadImage: Function = null;

    public var Unload: Function = null;

    public var DoesIconDataResourceExist: Function = null;

    public var LoadMovie: Function = null;

    public var OptionsFlag: Function = null;

    public var SetGenericParam: Function = null;

    public var GetGenericParam: Function = null;

    public var GetMappedFontName: Function = null;

    public var HasBeenClosedForInvocations: Function = null;

    public var Unescape: Function = null;

    public function CommunicationManager() {
      super();
    }
  }
}