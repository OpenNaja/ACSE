package {
  import core.applications.UIApplication;
  import scaleform.gfx.Extensions;
  import flash.display.Sprite;
  import flash.display.MovieClip;
  import flash.system.System;

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
      System.setClipboard(logBox.text);
    }

  }
}