package core.managers {
  public class CommunicationManagerFactory {

    public static var instance: CommunicationManagerFactory = new CommunicationManagerFactory();

    public var getCommunicationManagerObject: Function = null;

    public function CommunicationManagerFactory() {
      super();
      if (instance != null) {
        throw Error("Multiple CommunicationManagerFactory instances are being created!");
      }
    }
  }
}