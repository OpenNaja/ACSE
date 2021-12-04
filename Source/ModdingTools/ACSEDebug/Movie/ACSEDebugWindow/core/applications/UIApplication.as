package core.applications {
  import core.MovieGlobals;
  import core.managers.CommunicationManager;
  import core.managers.CommunicationManagerFactory;
  import flash.display.Loader;
  import flash.display.MovieClip;
  import flash.events.Event;
  import flash.external.ExternalInterface;
  import flash.net.URLRequest;
  import flash.system.ApplicationDomain;
  import flash.system.LoaderContext;
  import scaleform.gfx.Extensions;

  public class UIApplication extends MovieClip {

    public static var instance: UIApplication;

    public static var readyForInvokes: Boolean = false;

    public static var communicationManager: Object;

    public var isOpen: Boolean = false;

    public var isClosing: Boolean = false;

    public var manualReadyForInvokes: Boolean = false;

    public var dynamicLibraries: Array;

    private var _dynamicLibraryLoaders: Vector.<Loader>;

    private var _numDynamicLibrariesLoaded: int;

    public function UIApplication() {
      this.dynamicLibraries = [];
      if (MovieGlobals.verboseTrace) {
        trace("UIApplication() : " + this);
        trace("Compiled as release.");
      }
      MovieGlobals.rootDisplayObject = this;
      if (stage) {
        MovieGlobals.stage = stage;
        MovieGlobals.authoredStageWidth = stage.stageWidth;
        MovieGlobals.authoredStageHeight = stage.stageHeight;
      } else {
        addEventListener(Event.ADDED_TO_STAGE, this.addedToStageHandler);
      }
      instance = this;
      Extensions.enabled = true;
      visible = false;
      if (Extensions.isScaleform) {
        ExternalInterface.call("BindDirectInterfaces");
        communicationManager = CommunicationManagerFactory.instance.getCommunicationManagerObject();
      } else {
        communicationManager = new CommunicationManager();
      }
      addEventListener(Event.ENTER_FRAME, this.__preInit);
      super();
    }

    private function __preInit(param1: Event): void {
      removeEventListener(Event.ENTER_FRAME, this.__preInit);
      this.preInit();
    }

    private function addedToStageHandler(param1: Event): void {
      removeEventListener(Event.ADDED_TO_STAGE, this.addedToStageHandler);
      MovieGlobals.authoredStageWidth = stage.stageWidth;
      MovieGlobals.authoredStageHeight = stage.stageHeight;
      MovieGlobals.stage = stage;
    }

    protected function open(): void {
      if (MovieGlobals.verboseTrace) {
        trace("UIApplication.open()");
      }
      this.isClosing = false;
      if (this.isOpen) {
        return;
      }
      this.isOpen = true;
      visible = true;
      communicationManager.UIOpened();
    }

    public function close(): void {
      if (!this.isOpen) {
        return;
      }
      if (this.isClosing) {
        return;
      }
      if (MovieGlobals.verboseTrace) {
        trace("UIApplication.close()");
      }
      this.isClosing = true;
      this.playCloseAnimation();
    }

    public function enable(): void {
      enabled = true;
      mouseChildren = true;
    }

    public function disable(): void {
      enabled = false;
      mouseChildren = false;
    }

    public function unload(): void {
      if (!this.isOpen) {
        return;
      }
      if (!this.isClosing) {
        return;
      }
      if (MovieGlobals.verboseTrace) {
        trace("UIApplication.unload()");
      }
      this.isClosing = false;
      this.isOpen = false;
      visible = false;
      dispatchEvent(new Event(Event.UNLOAD));
      communicationManager.UIClosed();
    }

    protected function preInit(): void {
      var libraryName: String = null;
      var libLoader: Loader = null;
      if (this.dynamicLibraries == null || this.dynamicLibraries.length == 0) {
        this.doPreInit();
        return;
      }
      this._dynamicLibraryLoaders = new Vector.<Loader>();
      var libIndex: int = 0;
      while (libIndex < this.dynamicLibraries.length) {
        libraryName = this.dynamicLibraries[libIndex];
        libLoader = new Loader();
        this._dynamicLibraryLoaders.push(libLoader);
        libLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.dyanamicLibraryLoadCompleteHandler);
        libLoader.load(new URLRequest(libraryName), new LoaderContext(false, ApplicationDomain.currentDomain));
        libIndex++;
      }
    }

    private function doPreInit(): void {
      if (MovieGlobals.verboseTrace) {
        trace("UIApplication.preInit()");
      }
      if (stage) {
        stage.scaleMode = "noScale";
        stage.align = "TL";
      }
      communicationManager.AddListener("Open", this.open);
      communicationManager.AddListener("Close", this.close);
      communicationManager.AddListener("Enable", this.enable);
      communicationManager.AddListener("Disable", this.disable);
      this.init();
      if (!this.manualReadyForInvokes) {
        communicationManager.SetReadyForInvokes();
      }
    }

    private function dyanamicLibraryLoadCompleteHandler(param1: Event): void {
      ++this._numDynamicLibrariesLoaded;
      if (this._numDynamicLibrariesLoaded == this._dynamicLibraryLoaders.length) {
        this.doPreInit();
      }
    }

    protected function init(): void {}

    protected function playCloseAnimation(): void {
      if (MovieGlobals.verboseTrace) {
        trace("UIApplication.playCloseAnimation()");
      }
      this.unload();
    }
  }
}