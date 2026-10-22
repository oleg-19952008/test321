package net.bigpoint.darkorbit.net
{
   import flash.utils.Dictionary;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.QuestManager;
   
   public class QuestAssembly
   {
      
      private var delegateDict:Dictionary;
      
      private var main:Main;
      
      public function QuestAssembly()
      {
         super();
         this.initDelegateDict();
      }
      
      private static function hidden() : void
      {
      }
      
      private function initDelegateDict() : void
      {
         this.delegateDict = new Dictionary();
         this.delegateDict[ServerCommands.QUESTFM_INIT] = this.assembleQuestInit;
         this.delegateDict[ServerCommands.QUESTFM_UPDATE] = this.assembleQuestUpdate;
         this.delegateDict[ServerCommands.QUESTFM_PRIVILEGE_QUEST] = this.assemblePrivilegedQuest;
         this.delegateDict[ServerCommands.QUESTFM_ACCOMPLISH_QUEST] = this.assembleQuestAccomplished;
         this.delegateDict[ServerCommands.QUESTFM_CANCEL_QUEST] = this.assembleQuestCancelled;
         this.delegateDict[ServerCommands.QUESTFM_FAIL_QUEST] = this.assembleQuestFailed;
      }
      
      private function assembleQuestFailed(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         this.main.getQuestManager().setQuestFailed(_loc2_);
      }
      
      private function assembleQuestCancelled(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         this.main.getQuestManager().setQuestCancelled(_loc2_);
      }
      
      private function assembleQuestAccomplished(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         this.main.getQuestManager().setQuestAccomplished(_loc2_,_loc3_);
      }
      
      private function assemblePrivilegedQuest(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         this.main.getQuestManager().privilegeQuestByID(_loc2_);
      }
      
      private function assembleQuestUpdate(param1:Array) : void
      {
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:Boolean = false;
         var _loc2_:int = int(param1[3]);
         var _loc3_:String = param1[4];
         switch(_loc3_)
         {
            case "o":
               break;
            case "i":
               _loc4_ = int(param1[5]);
               _loc5_ = int(param1[6]);
               _loc6_ = int(param1[7]);
               _loc7_ = Boolean(int(param1[8]));
               this.main.getQuestManager().updateCondition(_loc2_,_loc4_,_loc5_,_loc6_,_loc7_);
         }
      }
      
      private function assembleQuestInit(param1:Array) : void
      {
         var _loc2_:String = null;
         _loc2_ = param1[3];
         var _loc3_:String = _loc2_.charAt(0);
         if(_loc3_ == "{")
         {
            this.main.getConnectionManager().sendCommand(ServerCommands.QUESTFM_INFO,["s","f",QuestManager.QUESTFM_INI_FMT_XML]);
            this.main.getConnectionManager().sendCommand(ServerCommands.QUESTFM_INFO,["g"]);
            return;
         }
         this.main.getQuestManager().iniFormat = QuestManager.QUESTFM_INI_FMT_XML;
         var _loc4_:String = "";
         if(param1[4] != undefined)
         {
            _loc4_ = param1[4];
         }
         this.main.getQuestManager().initQuest(_loc2_,_loc4_);
      }
      
      public function assembleCommand(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
      }
      
      public function setMain(param1:Main) : void
      {
         if(this.main == null)
         {
            this.main = param1;
         }
      }
   }
}

