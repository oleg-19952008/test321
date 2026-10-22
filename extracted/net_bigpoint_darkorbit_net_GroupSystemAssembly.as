package net.bigpoint.darkorbit.net
{
   import flash.utils.Dictionary;
   import net.bigpoint.darkorbit.Main;
   
   public class GroupSystemAssembly extends BaseAssembly
   {
      
      private static var _instance:GroupSystemAssembly;
      
      private var delegateDict:Dictionary;
      
      private var main:Main;
      
      public function GroupSystemAssembly(param1:Function)
      {
         super();
         if(param1 !== hidden)
         {
            throw new Error("SettingsAssembly is a Singleton and can only be accessed through GroupSystemAssembly.getInstance()");
         }
         this.main = _main;
         this.initDelegateDict();
      }
      
      public static function getInstance() : GroupSystemAssembly
      {
         if(_instance == null)
         {
            _instance = new GroupSystemAssembly(hidden);
         }
         return _instance;
      }
      
      private static function hidden() : void
      {
      }
      
      private function initDelegateDict() : void
      {
         this.delegateDict = new Dictionary();
         this.delegateDict[ServerCommands.GROUPSYSTEM_ERROR] = this.assembleGroupSystemError;
         this.delegateDict[ServerCommands.GROUPSYSTEM_GROUP_EVENT_UPDATE] = this.assembleGroupEventUpdate;
         this.delegateDict[ServerCommands.GROUPSYSTEM_INIT] = this.assembleGroupSystemInit;
         this.delegateDict[ServerCommands.GROUPSYSTEM_GROUP_INVITE] = this.assembleGroupSystemInvite;
         this.delegateDict[ServerCommands.GROUPSYSTEM_GROUP_EVENT_END] = this.assembleGroupEventEnd;
         this.delegateDict[ServerCommands.GROUPSYSTEM_GROUP_EVENT_PING] = this.assembleGroupEventPing;
         this.delegateDict[ServerCommands.GROUPSYSTEM_GROUP_EVENT_MEMBER_LEAVES] = this.assembleGroupMemberLeaves;
         this.delegateDict[ServerCommands.GROUPSYSTEM_GROUP_EVENT_KILL] = this.assembleGroupEventKill;
         this.delegateDict[ServerCommands.GROUPSYSTEM_GROUP_EVENT_ERROR] = this.assembleGroupEventError;
         this.delegateDict[ServerCommands.GROUPSYSTEM_GROUP_EVENT_JUMP] = this.assembleGroupEventJump;
         this.delegateDict[ServerCommands.GROUPSYSTEM_GROUP_EVENT_NEW_LEADER] = this.assembleGroupEventNewLeader;
         this.delegateDict[ServerCommands.GROUPSYSTEM_GROUP_EVENT_INVITATION_BEHAVIOUR_CHANGE] = this.assembleGroupEventChangeInvitationBehaviour;
         this.delegateDict[ServerCommands.GROUPSYSTEM_INIT_UI] = this.assembleGroupEventInit;
         this.delegateDict[ServerCommands.GROUPSYSTEM_BLOCK_INVITATIONS] = this.assembleGroupEventBlockInvitation;
      }
      
      private function assembleGroupSystemError(param1:Array) : void
      {
         var _loc2_:String = param1[3];
         switch(_loc2_)
         {
            case ServerCommands.GROUPSYSTEM_ERROR_CONNECTION:
               this.main.getGroupManager().terminateGroup();
               this.main.getGroupManager().deleteAllInvitations();
         }
      }
      
      private function assembleGroupSystemInit(param1:Array) : void
      {
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc2_:String = param1[3];
         switch(_loc2_)
         {
            case ServerCommands.GROUPSYSTEM_INIT_SUB_GROUP:
               param1.splice(0,4);
               _loc3_ = int(param1.shift());
               _loc4_ = int(param1.shift());
               _loc5_ = int(param1.shift());
               _loc6_ = int(param1.shift());
               _loc7_ = int(param1.shift());
               this.main.getGroupManager().initGroupWithMembers(_loc3_,_loc4_,_loc5_,_loc6_,_loc7_,param1);
               break;
            case ServerCommands.GROUPSYSTEM_INIT_SUB_PLAYER:
         }
      }
      
      private function assembleGroupSystemInvite(param1:Array) : void
      {
         var _loc3_:String = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:String = null;
         var _loc2_:String = param1[3];
         switch(_loc2_)
         {
            case ServerCommands.GROUPSYSTEM_GROUP_INVITE_SUB_BY_ID:
               param1.splice(0,4);
               this.main.getGroupManager().handleRawInvitation(param1);
               break;
            case ServerCommands.GROUPSYSTEM_GROUP_INVITE_SUB_DELETE:
               _loc3_ = param1[4];
               _loc4_ = int(param1[5]);
               _loc5_ = int(param1[6]);
               this.main.getGroupManager().deleteInvitation(_loc4_,_loc5_,_loc3_);
               break;
            case ServerCommands.GROUPSYSTEM_GROUP_INVITE_SUB_ERROR:
               _loc6_ = param1[4];
               this.main.getGroupManager().handleInvitationError(_loc6_);
         }
      }
      
      private function assembleGroupEventBlockInvitation(param1:Array) : void
      {
         var _loc2_:Boolean = Boolean(int(param1[3]));
         this.main.getGroupManager().changeBlockInvitationsState(_loc2_);
      }
      
      private function assembleGroupEventInit(param1:Array) : void
      {
         this.main.getGroupManager();
      }
      
      private function assembleGroupEventChangeInvitationBehaviour(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         this.main.getGroupManager().handleInvitationBehaviourChange(_loc2_);
      }
      
      private function assembleGroupEventNewLeader(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         this.main.getGroupManager().handleLeaderChange(_loc2_);
      }
      
      private function assembleGroupEventJump(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         this.main.getGroupManager().handleMemberJump(_loc2_);
      }
      
      private function assembleGroupEventError(param1:Array) : void
      {
         var _loc2_:String = param1[3];
         var _loc3_:int = -1;
         if(param1[4] != null)
         {
            _loc3_ = int(param1[4]);
         }
         this.main.getGroupManager().handleGroupError(_loc2_,_loc3_);
      }
      
      private function assembleGroupEventKill(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         this.main.getGroupManager().handleMemberKill(_loc2_);
      }
      
      private function assembleGroupMemberLeaves(param1:Array) : void
      {
         var _loc2_:String = param1[3];
         var _loc3_:int = int(param1[4]);
         this.main.getGroupManager().onMemberLeft(_loc3_,_loc2_);
      }
      
      private function assembleGroupEventPing(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         this.main.getGroupManager().createMapmarker(0,0,_loc2_,_loc3_);
      }
      
      private function assembleGroupEventEnd(param1:Array) : void
      {
         this.main.getGroupManager().terminateGroup();
      }
      
      private function assembleGroupEventUpdate(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         var _loc3_:XML = new XML(param1[4]);
         this.main.getGroupManager().updateMemberStats(_loc2_,_loc3_);
      }
      
      private function defaultCaseDelegate(param1:Array) : void
      {
      }
      
      public function assembleGroupSystemEvent(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
         else
         {
            this.defaultCaseDelegate(param1);
         }
      }
   }
}

