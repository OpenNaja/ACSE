package core {
  import flash.display.Sprite;
  import flash.display.Stage;

  public class MovieGlobals {

    public static var displayAudioTriggersOnStage: Boolean = false;

    public static var haltOnTranslationError: Boolean = false;

    public static var rootDisplayObject: Sprite;

    public static var stage: Stage;

    public static var authoredStageWidth: Number;

    public static var authoredStageHeight: Number;

    public static var appContainerScale: Number = 1;

    public static var verboseTrace: Boolean = false;

    public static var verboseAudioTrace: Boolean = false;

    public function MovieGlobals() {
      super();
    }
  }
}