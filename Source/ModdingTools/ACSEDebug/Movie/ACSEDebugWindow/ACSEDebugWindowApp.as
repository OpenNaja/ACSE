package {
  import core.applications.UIApplication;
  import scaleform.gfx.Extensions;
  import flash.display.Sprite;
  import flash.display.MovieClip;
  import flash.system.System;
  import flash.desktop.Clipboard;
  import flash.desktop.ClipboardFormats;
  import flash.desktop.ClipboardTransferMode;
  import flash.events.MouseEvent; 


  public class ACSEDebugWindowApp extends UIApplication {

    //@TODO: Move all movie content to the Sprite layer and make hide/show smoother
    private var mylayer: Sprite;

    public function ACSEDebugWindowApp() {
      super();
    }

    override protected function init(): void {
      super.init();
	  
      UIApplication.communicationManager.AddListener("Show", this.show);
      UIApplication.communicationManager.AddListener("Hide", this.hide);
      UIApplication.communicationManager.AddListener("AddLog", this.AddLog);
      UIApplication.communicationManager.AddListener("SetCommand", this.SetCommand);
      UIApplication.communicationManager.AddListener("IncreaseScroll", this.IncreaseScroll);
      UIApplication.communicationManager.AddListener("DecreaseScroll", this.DecreaseScroll);
      UIApplication.communicationManager.AddListener("ClearLog", this.ClearLog);
      UIApplication.communicationManager.AddListener("CopyLog", this.CopyLog);
   
      this.mylayer = new Sprite();
      this.mylayer.visible = false;
      addChild(this.mylayer);
	  
      this.hide();

      logBox.appendText("ACSEDebugWindow.init()\n");
      cmdInput.appendText("Enter command");
	  logBox.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownScroll);
	  logBox.addEventListener(MouseEvent.MOUSE_UP, mouseUpScroll);
	  
    }
	
	public function mouseDownScroll(event:MouseEvent):void 
    { 
       logBox.scrollV++; 
	}
	public function mouseUpScroll(event:MouseEvent):void 
    { 
       logBox.scrollV--; 
	}

    private function show(): void {
      this.mylayer.visible = true;
      logBox.visible = true;
      cmdInput.visible = true;
      defbgclip.visible = true;
    }

    private function hide(): void {
      this.mylayer.visible = false;
      logBox.visible = false;
      cmdInput.visible = false;
      defbgclip.visible = false;
    }

    public function IncreaseScroll(): * {
      logBox.scrollV = logBox.scrollV + 30;
      if (logBox.scrollV > logBox.maxScrollV) {
        logBox.scrollV = logBox.maxScrollV;
      }
    }

    public function DecreaseScroll(): * {
      logBox.scrollV = logBox.scrollV - 30;
      if (logBox.scrollV <= 0) {
        logBox.scrollV = 0;
      }
    }

    public function AddLog(param1: String): * {
      logBox.appendText(param1);
      logBox.scrollV = logBox.maxScrollV;
    }

    public function SetCommand(param1: String): * {
      cmdInput.text = "";
      cmdInput.appendText(param1);
      cmdInput.setSelection(cmdInput.length, cmdInput.length);
    }

    public function ClearLog(): * {
      logBox.text = "";
      logBox.scrollV = logBox.maxScrollV;
    }

	public function CopyLog(): * {
      logBox.appendText("Trying to copy to clipboard");
      logBox.scrollV = logBox.maxScrollV;

	  //System.setClipboard(logBox.text);
	  System.setClipboard("Copied from the movie");
      Clipboard.generalClipboard.clear();
      Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, "Im copied from a script");
	}

  }
}