package net.bigpoint.darkorbit.net
{
   import com.bigpoint.filecollection.finish.SWFFinisher;
   import com.bigpoint.utils.BPLocale;
   import com.bigpoint.utils.TextReplacementList;
   import flash.display.MovieClip;
   import flash.utils.Dictionary;
   import net.bigpoint.darkorbit.Hero;
   import net.bigpoint.darkorbit.InGameCatalog;
   import net.bigpoint.darkorbit.Main;
   import net.bigpoint.darkorbit.ResourceManager;
   import net.bigpoint.darkorbit.ScreenManager;
   import net.bigpoint.darkorbit.audio.AudioManager;
   import net.bigpoint.darkorbit.collectable.Collectable;
   import net.bigpoint.darkorbit.combat.CombatManager;
   import net.bigpoint.darkorbit.combat.ExplosionPattern;
   import net.bigpoint.darkorbit.data.vo.RankedHuntStatsVO;
   import net.bigpoint.darkorbit.gui.container.SimpleContainer;
   import net.bigpoint.darkorbit.gui.windows.SimpleWindow;
   import net.bigpoint.darkorbit.map.Map;
   import net.bigpoint.darkorbit.pattern.EffectPattern;
   import net.bigpoint.darkorbit.pattern.PatternManager;
   import net.bigpoint.darkorbit.settings.Settings;
   import net.bigpoint.darkorbit.ship.MapObject;
   import net.bigpoint.darkorbit.ship.ShipManager;
   import net.bigpoint.darkorbit.ship.effects.EffectIDList;
   import net.bigpoint.darkorbit.ship.effects.EffectsManager;
   import net.bigpoint.darkorbit.ship.effects.InvincibilityEffect;
   import net.bigpoint.darkorbit.ship.effects.RageEffect;
   import net.bigpoint.darkorbit.ship.effects.SaboteurEffect;
   import net.bigpoint.darkorbit.ship.effects.SkullEffect;
   import net.bigpoint.darkorbit.ship.effects.SpeedBuffEffect;
   
   public class MapEventsAssembly extends BaseAssembly
   {
      
      private static var instance:MapEventsAssembly;
      
      private var map:Map;
      
      private var main:Main;
      
      private var delegateDict:Dictionary;
      
      private var effectsManager:EffectsManager = EffectsManager.getInstance();
      
      public function MapEventsAssembly(param1:Function)
      {
         super();
         if(param1 !== hidden)
         {
            throw new Error("MapEventsAssembly is a Singleton and can only be accessed through MapEventsAssembly.getInstance()");
         }
         this.main = _main;
         this.initDelegateDict();
      }
      
      public static function getInstance() : MapEventsAssembly
      {
         if(instance == null)
         {
            instance = new MapEventsAssembly(hidden);
         }
         return instance;
      }
      
      private static function hidden() : void
      {
      }
      
      private function initDelegateDict() : void
      {
         this.delegateDict = new Dictionary();
         this.delegateDict[ServerCommands.SET_PLAYER_ATTACKABLE] = this.assembleSetPlayerAttackable;
         this.delegateDict[ServerCommands.DISPLAY_MESSAGE] = this.assembleDisplayMessage;
         this.delegateDict[ServerCommands.TARGET_FADE_TO_GRAY] = this.assembleTargetFadeToGray;
         this.delegateDict[ServerCommands.TARGET_FADE_TO_GRAY_ABORT] = this.assembleTargetFadeToGrayAbort;
         this.delegateDict[ServerCommands.TARGET_INVISIBLE] = this.assembleTargetInvisible;
         this.delegateDict[ServerCommands.SET_DRONES] = this.assembleSetDrones;
         this.delegateDict[ServerCommands.SET_DRONE_DISPLAY] = this.assembleSetDroneDisplay;
         this.delegateDict[ServerCommands.EMP_MALUS_BOLT] = this.assembleEmpMalusBolt;
         this.delegateDict[ServerCommands.ENEMY_WARNING] = this.assembleEnemyWarning;
         this.delegateDict[ServerCommands.SPAWN_ENEMIES] = this.assembleSpawnEnemies;
         this.delegateDict[ServerCommands.SET_TITLE] = this.assembleSetTitle;
         this.delegateDict[ServerCommands.REMOVE_TITLE] = this.assembleRemoveTitle;
         this.delegateDict[ServerCommands.SET_PERMANENT_TITLE] = this.assembleSetPermanentTitle;
         this.delegateDict[ServerCommands.MALUS] = this.assembleMalus;
         this.delegateDict[ServerCommands.SMARTBOMB] = this.assembleSmartbomb;
         this.delegateDict[ServerCommands.INSTASHIELD] = this.assembleInstashield;
         this.delegateDict[ServerCommands.EMP] = this.assembleEmp;
         this.delegateDict[ServerCommands.TECHS_UPDATE] = this.assembleTechsUpdate;
         this.delegateDict[ServerCommands.SET_PORTAL] = this.assembleSetPortal;
         this.delegateDict[ServerCommands.BOOSTER_FOUND] = this.assembleBoosterFound;
         this.delegateDict[ServerCommands.FIREWORKS_IGNITE] = this.assembleFireworksIgnite;
         this.delegateDict[ServerCommands.FIREWORKS_IGNITE_GROUP] = this.assembleFireworksIgniteGroup;
         this.delegateDict[ServerCommands.INDEPENDENCE_DAY_MODE] = this.assembleIndependenceDayMode;
         this.delegateDict[ServerCommands.INIT_SCOREBOARD] = this.assembleInitScoreboard;
         this.delegateDict[ServerCommands.SET_SCORE] = this.assembleSetScore;
         this.delegateDict[ServerCommands.SET_SPEED] = this.assembleSetSpeed;
         this.delegateDict[ServerCommands.INIT_INVASION_SCOREBOARD] = this.assembleInitInvasionScoreboard;
         this.delegateDict[ServerCommands.SET_INVASION_SCORE] = this.assembleSetInvasionScore;
         this.delegateDict[ServerCommands.SET_INVASION_WAVE] = this.assembleSetInvasionWave;
         this.delegateDict[ServerCommands.CTB] = this.assembleCtb;
         this.delegateDict[ServerCommands.TEAM_DEATHMATCH] = this.assembleTeamDeathmatch;
         this.delegateDict[ServerCommands.SKILL_DESIGNS] = this.assembleSkillDesigns;
         this.delegateDict[ServerCommands.MINE_EXPLODE] = this.assembleMineExplode;
         this.delegateDict[ServerCommands.RANKED_HUNT_EVENT_UPDATE] = this.assembleRankedHuntEventUpdate;
         this.delegateDict[ServerCommands.PLAY_SPECIAL_EXPLOSION] = this.assemblePlaySpecialExplosion;
         this.delegateDict[ServerCommands.SAB_SHOT] = this.assembleSabShot;
         this.delegateDict[ServerCommands.SPAWN] = this.assembleSpawn;
         this.delegateDict[ServerCommands.DESPAWN] = this.assembleSpawn;
         this.delegateDict[ServerCommands.HEAL_RAY] = this.assembleHealRay;
         this.delegateDict[ServerCommands.GRAPHIC_FX] = this.assembleGraphicFx;
      }
      
      public function assembleSubCommand(param1:Array) : void
      {
         var _loc2_:String = param1[3];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
      }
      
      public function assembleCommand(param1:Array) : void
      {
         var _loc2_:String = param1[2];
         if(this.delegateDict[_loc2_] != null)
         {
            this.delegateDict[_loc2_](param1);
         }
      }
      
      private function assemblePlaySpecialExplosion(param1:Array) : void
      {
         var _loc3_:MapObject = null;
         var _loc2_:int = int(param1[3]);
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc3_ = this.map.getShipManager().getShip(_loc2_);
            if(_loc3_ != null)
            {
               _loc3_.explodeTypeID = 6;
               AudioManager.playSoundEffect(75,false,false,_loc3_.x,_loc3_.y,true);
            }
         }
      }
      
      private function assembleSabShot(param1:Array) : void
      {
         var _loc4_:CombatManager = null;
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc4_ = this.map.getCombatManager();
            if(_loc4_ != null)
            {
               _loc4_.addChasingShot(_loc2_,_loc3_,"sab_shot");
            }
         }
      }
      
      private function assembleSpawn(param1:Array) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:MapObject = null;
         if(param1.length == 4)
         {
            _loc6_ = int(param1[3]);
            _loc7_ = this.main.screenManager.map.getShipManager().getShip(_loc6_);
            if(_loc7_ == null)
            {
               return;
            }
            _loc2_ = _loc7_.x;
            _loc3_ = _loc7_.y;
         }
         else
         {
            if(param1.length != 5)
            {
               return;
            }
            _loc2_ = int(param1[3]);
            _loc3_ = int(param1[4]);
         }
         var _loc4_:SWFFinisher = SWFFinisher(ResourceManager.fileCollection.getFinisher("spawn0"));
         var _loc5_:MovieClip = MovieClip(_loc4_.getEmbededMovieClip("mc"));
         this.main.screenManager.getExplosionLayer().addChild(_loc5_);
         _loc5_.x = _loc2_;
         _loc5_.y = _loc3_;
         ScreenManager.playAnimation(_loc5_,20,false,1,true);
         AudioManager.playSoundEffect(79,false,false,_loc2_,_loc3_,true);
      }
      
      private function assembleHealRay(param1:Array) : void
      {
         var _loc4_:CombatManager = null;
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         if(this.map != null)
         {
            _loc4_ = this.map.getCombatManager();
            if(_loc4_ != null)
            {
               _loc4_.addHealingBeam(_loc2_,_loc3_);
            }
         }
      }
      
      private function assembleGraphicFx(param1:Array) : void
      {
         var _loc6_:MapObject = null;
         var _loc7_:RageEffect = null;
         var _loc8_:SaboteurEffect = null;
         var _loc9_:SpeedBuffEffect = null;
         var _loc10_:SkullEffect = null;
         var _loc11_:InvincibilityEffect = null;
         var _loc2_:ShipManager = this.main.screenManager.map.getShipManager();
         var _loc3_:int = int(param1[5]);
         var _loc4_:String = param1[3];
         var _loc5_:String = param1[4];
         if(_loc4_ == ServerCommands.GRAPHIC_FX_START)
         {
            _loc6_ = _loc2_.getShip(_loc3_);
            if(_loc5_ == ServerCommands.GRAPHIC_FX_RAGE)
            {
               if(_loc6_ != null && !this.effectsManager.doesEffectExistOn(_loc6_,EffectIDList.RAGE))
               {
                  _loc7_ = new RageEffect(EffectIDList.RAGE,new EffectPattern(EffectIDList.RAGE,""),false,[_loc6_]);
                  this.effectsManager.addEffect(_loc7_,_loc6_);
                  AudioManager.playSoundEffect(78,false,false,_loc6_.x,_loc6_.y,true);
               }
            }
            else if(_loc5_ == ServerCommands.GRAPHIC_FX_SABOTEUR_DEBUFF)
            {
               if(_loc6_ != null && !this.effectsManager.doesEffectExistOn(_loc6_,EffectIDList.SABOTEUR_SLOW_DOWN_EFFECT))
               {
                  _loc8_ = new SaboteurEffect(EffectIDList.SABOTEUR_SLOW_DOWN_EFFECT,new EffectPattern(EffectIDList.SABOTEUR_SLOW_DOWN_EFFECT,"slow-effect"));
                  this.effectsManager.addEffect(_loc8_,_loc6_,EffectsManager.ROTATION_DEPENDANT_EFFECT);
                  _loc6_.isDebuffed = true;
               }
            }
            else if(_loc5_ == ServerCommands.SPEED_BUFF)
            {
               _loc9_ = new SpeedBuffEffect(EffectIDList.SPEED_BUFF_EFFECT,new EffectPattern(EffectIDList.SPEED_BUFF_EFFECT,"speed-buff-effect"));
               this.effectsManager.addEffect(_loc9_,_loc2_.getShip(_loc3_),EffectsManager.ROTATION_DEPENDANT_EFFECT);
            }
            else if(_loc5_ == ServerCommands.GRAPHIC_FX_SKULL)
            {
               if(_loc6_ != null && !this.effectsManager.doesEffectExistOn(_loc6_,EffectIDList.SKULL))
               {
                  _loc10_ = new SkullEffect(EffectIDList.SKULL,new EffectPattern(EffectIDList.SKULL,"skull"));
                  this.effectsManager.addEffect(_loc10_,_loc6_);
               }
            }
            else if(_loc5_ == ServerCommands.GRAPHIC_FX_INVINCIBILITY)
            {
               if(_loc6_ != null && !this.effectsManager.doesEffectExistOn(_loc6_,EffectIDList.INVINCIBILITY))
               {
                  _loc11_ = new InvincibilityEffect(EffectIDList.INVINCIBILITY,new EffectPattern(EffectIDList.INVINCIBILITY,"invincibilityShield"));
                  this.effectsManager.addEffect(_loc11_,_loc6_);
                  AudioManager.playSoundEffect(80,false,false,_loc6_.x,_loc6_.y,true);
               }
            }
            else if(_loc5_ == ServerCommands.GRAPHIC_FX_KAMIKAZE)
            {
               if(_loc6_ != null)
               {
                  AudioManager.playSoundEffect(75,false,false,_loc6_.x,_loc6_.y,true);
               }
            }
         }
         else if(_loc4_ == ServerCommands.GRAPHIC_FX_END)
         {
            if(_loc5_ == ServerCommands.GRAPHIC_FX_RAGE)
            {
               _loc6_ = _loc2_.getShip(_loc3_);
               this.effectsManager.removeEffectByIdFromEntity(_loc6_,EffectIDList.RAGE);
            }
            else if(_loc5_ == ServerCommands.GRAPHIC_FX_SABOTEUR_DEBUFF)
            {
               _loc6_ = _loc2_.getShip(_loc3_);
               if(_loc6_ != null)
               {
                  this.effectsManager.removeEffectByIdFromEntity(_loc6_,EffectIDList.SABOTEUR_SLOW_DOWN_EFFECT);
                  _loc6_.isDebuffed = false;
               }
            }
            else if(_loc5_ == ServerCommands.SPEED_BUFF)
            {
               this.effectsManager.removeEffectByIdFromEntity(_loc2_.getShip(_loc3_),EffectIDList.SPEED_BUFF_EFFECT);
            }
            else if(_loc5_ == ServerCommands.GRAPHIC_FX_SKULL)
            {
               this.effectsManager.removeEffectByIdFromEntity(_loc2_.getShip(_loc3_),EffectIDList.SKULL);
            }
            else if(_loc5_ == ServerCommands.GRAPHIC_FX_INVINCIBILITY)
            {
               _loc6_ = _loc2_.getShip(_loc3_);
               if(_loc6_ != null)
               {
                  this.effectsManager.removeEffectByIdFromEntity(_loc6_,EffectIDList.INVINCIBILITY);
               }
            }
         }
      }
      
      private function assembleSetPlayerAttackable(param1:Array) : void
      {
         var _loc4_:MapObject = null;
         var _loc2_:Boolean = Boolean(int(param1[4]));
         var _loc3_:int = int(param1[3]);
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc4_ = this.map.getShipManager().getShip(_loc3_);
            if(_loc4_ != null)
            {
               _loc4_.changeAttackableStateInNonPvPMap(_loc2_);
            }
         }
         if(_loc4_ != null)
         {
            if(_loc2_)
            {
               this.main.getGuiManager().writeToLog(BPLocale.getText("msg_recovery_of_ceasefire").replace(/%nick%/,_loc4_.getUsername()));
            }
            else
            {
               this.main.getGuiManager().writeToLog(BPLocale.getText("msg_loss_of_ceasefire").replace(/%nick%/,_loc4_.getUsername()));
            }
         }
      }
      
      private function assembleDisplayMessage(param1:Array) : void
      {
         var _loc5_:TextReplacementList = null;
         var _loc2_:String = param1[3];
         var _loc3_:int = int(param1[4]);
         var _loc4_:String = BPLocale.getText(param1[5]);
         if(param1[6] != undefined)
         {
            _loc5_ = TextReplacementList.parseRawTextReplacement(param1[6]);
            _loc4_ = _loc5_.replace(_loc4_);
         }
         this.main.getGuiManager().addNotification(_loc4_);
      }
      
      private function assembleTargetFadeToGray(param1:Array) : void
      {
         var _loc4_:MapObject = null;
         this.map = this.main.screenManager.map;
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         if(_loc3_ != Hero.userID)
         {
            if(this.map != null)
            {
               _loc4_ = this.map.getShipManager().getShip(_loc2_);
               if(_loc4_ != null && !_loc4_.isGroupMember)
               {
                  _loc4_.setCrossHairColor(MapObject.CROSSHAIR_GRAY);
               }
            }
         }
      }
      
      private function assembleTargetFadeToGrayAbort(param1:Array) : void
      {
         var _loc3_:MapObject = null;
         this.map = this.main.screenManager.map;
         var _loc2_:int = int(param1[3]);
         if(this.map != null)
         {
            _loc3_ = this.map.getShipManager().getShip(_loc2_);
            if(_loc3_ != null)
            {
               _loc3_.setCrossHairColor(MapObject.CROSSHAIR_RED);
            }
         }
      }
      
      private function assembleTargetInvisible(param1:Array) : void
      {
         var _loc4_:MapObject = null;
         var _loc2_:int = int(param1[3]);
         var _loc3_:Boolean = Boolean(int(param1[4]));
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc4_ = this.map.getShipManager().getShip(_loc2_);
            if(_loc4_ != null)
            {
               _loc4_.setCloak(_loc3_);
            }
         }
      }
      
      private function assembleSetDrones(param1:Array) : void
      {
         var _loc4_:MapObject = null;
         var _loc2_:int = int(param1[3]);
         var _loc3_:String = param1[4];
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc4_ = this.map.getShipManager().getShip(_loc2_);
            if(_loc4_ != null)
            {
               _loc4_.removeDrones();
               _loc4_.removeSimpleDroneDisplay();
               this.map.getDroneManager().parseDroneString(_loc2_,_loc3_);
               this.map.getDroneManager().deployDrones(_loc2_);
            }
         }
      }
      
      private function assembleSetDroneDisplay(param1:Array) : void
      {
         var _loc6_:MapObject = null;
         var _loc2_:int = int(param1[3]);
         var _loc3_:Array = String(param1[4]).split("/");
         var _loc4_:int = int(_loc3_[0]);
         var _loc5_:int = int(_loc3_[1]);
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc6_ = this.map.getShipManager().getShip(_loc2_);
            if(_loc6_ != null)
            {
               _loc6_.removeDrones();
               _loc6_.removeSimpleDroneDisplay();
               _loc6_.updateDroneDisplay(_loc4_,_loc5_);
            }
         }
      }
      
      private function assembleEmpMalusBolt(param1:Array) : void
      {
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            this.map.getMinimapManager().getMiniMap().startInterference(int(param1[3]));
         }
      }
      
      private function assembleEnemyWarning(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         this.main.getGuiManager().setThreadIndicator(_loc2_);
      }
      
      private function assembleSpawnEnemies(param1:Array) : void
      {
      }
      
      private function assembleSetTitle(param1:Array) : void
      {
         var _loc4_:MapObject = null;
         var _loc2_:int = int(param1[3]);
         var _loc3_:String = param1[4];
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc4_ = this.map.getShipManager().getShip(_loc2_);
            if(_loc4_ != null)
            {
               if(_loc3_ == "-1")
               {
                  _loc4_.removeTitle();
               }
               else
               {
                  _loc4_.updateTitle(BPLocale.getText(_loc3_));
               }
            }
         }
      }
      
      private function assembleRemoveTitle(param1:Array) : void
      {
         var _loc3_:MapObject = null;
         var _loc2_:int = int(param1[3]);
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc3_ = this.map.getShipManager().getShip(_loc2_);
            if(_loc3_ != null)
            {
               _loc3_.removeTitle();
            }
         }
      }
      
      private function assembleSetPermanentTitle(param1:Array) : void
      {
         var _loc4_:MapObject = null;
         var _loc2_:int = int(param1[3]);
         var _loc3_:String = param1[4];
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc4_ = this.map.getShipManager().getShip(_loc2_);
            if(_loc4_ != null)
            {
               if(_loc3_ == "-1")
               {
                  _loc4_.removePermanentTitle();
               }
               else
               {
                  _loc4_.updatePermanentTitle(BPLocale.getText(_loc3_));
               }
            }
         }
      }
      
      private function assembleMalus(param1:Array) : void
      {
         var _loc5_:MapObject = null;
         var _loc2_:String = param1[3];
         var _loc3_:int = int(param1[4]);
         var _loc4_:Boolean = _loc3_ == Hero.userID;
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc5_ = this.map.getShipManager().getShip(_loc3_);
            if(_loc5_ != null)
            {
               switch(_loc2_)
               {
                  case ServerCommands.MALUS_SET:
                     _loc5_.addMalus();
                     if(_loc4_)
                     {
                        this.main.getGuiManager().writeToLog(BPLocale.getText("msg_arms_harmed"));
                     }
                     break;
                  case ServerCommands.MALUS_REMOVE:
                     _loc5_.removeMalus();
                     if(_loc4_)
                     {
                        this.main.getGuiManager().writeToLog(BPLocale.getText("msg_arms_recovered"));
                     }
               }
            }
         }
      }
      
      private function assembleMultiplierFound(param1:Array) : void
      {
      }
      
      private function assembleSmartbomb(param1:Array) : void
      {
         var _loc4_:MapObject = null;
         var _loc5_:ExplosionPattern = null;
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = 0;
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc4_ = this.map.getShipManager().getShip(_loc2_);
            if(_loc4_ != null)
            {
               _loc5_ = PatternManager.getPyroPattern(ExplosionPattern.TYPE_SMARTBOMB_EXPLOSION,_loc3_);
               this.map.getCombatManager().showPyroEffect(_loc4_.x,_loc4_.y,_loc5_,50,true);
               AudioManager.playSoundEffect(30);
            }
         }
      }
      
      private function assembleInstashield(param1:Array) : void
      {
         var _loc4_:MapObject = null;
         var _loc5_:ExplosionPattern = null;
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = 0;
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc4_ = this.map.getShipManager().getShip(_loc2_);
            if(_loc4_ != null)
            {
               _loc5_ = PatternManager.getPyroPattern(ExplosionPattern.TYPE_INSTASHIELD,_loc3_);
               this.map.getCombatManager().showPyroEffectOnShip(_loc5_,_loc4_,50);
               AudioManager.playSoundEffect(31);
            }
         }
      }
      
      private function assembleEmp(param1:Array) : void
      {
         var _loc3_:MapObject = null;
         var _loc2_:int = int(param1[3]);
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc3_ = this.map.getShipManager().getShip(_loc2_);
            if(_loc3_ != null)
            {
               this.map.getCombatManager().addEMPtoShip(_loc3_);
            }
         }
      }
      
      private function assembleTechsUpdate(param1:Array) : void
      {
         TechAssembly.getInstance().assembleSubCommand(param1);
      }
      
      private function assembleSetPortal(param1:Array) : void
      {
         var _loc3_:int = 0;
         var _loc2_:String = param1[3];
         if(_loc2_ == ServerCommands.SET_PORTAL_REMOVE)
         {
            this.map = this.main.screenManager.map;
            if(this.map != null)
            {
               if(param1[4] == ServerCommands.SET_PORTAL_REMOVE_ALL)
               {
                  this.map.portalManager.deleteAllPortals();
               }
               else
               {
                  _loc3_ = int(param1[4]);
                  this.map.portalManager.deletePortal(_loc3_);
               }
            }
         }
      }
      
      private function assembleMineExplode(param1:Array) : void
      {
         var _loc2_:String = param1[3];
         var _loc3_:Map = this.main.screenManager.map;
         if(_loc3_ != null)
         {
            _loc3_.getMineManager().removeMine(_loc2_,true);
         }
      }
      
      private function assembleRankedHuntEventUpdate(param1:Array) : void
      {
         var _loc3_:int = 0;
         var _loc4_:RankedHuntStatsVO = null;
         var _loc2_:String = param1[3];
         switch(_loc2_)
         {
            case ServerCommands.RANKED_HUNT_EVENT_END:
               _loc3_ = int(param1[4]);
               if(Hero.rankedHuntingEventData != null && Hero.rankedHuntingEventData.eventVOs != null)
               {
                  _loc4_ = Hero.rankedHuntingEventData.eventVOs[_loc3_] as RankedHuntStatsVO;
                  if(_loc4_ != null)
                  {
                     delete Hero.rankedHuntingEventData.eventVOs[_loc3_];
                     this.main.getGuiManager().initUpdateRankedHuntStats(_loc3_);
                  }
               }
         }
      }
      
      private function assembleBoosterFound(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         var _loc4_:String = BPLocale.getText("booster_found");
         _loc4_ = _loc4_.replace("%BOOSTERNAME%",InGameCatalog.instance.boosterNames[_loc2_]);
         _loc4_ = _loc4_.replace("%HOURS%",_loc3_);
         this.main.getGuiManager().writeToLog(_loc4_);
      }
      
      private function assembleFireworksIgnite(param1:Array) : void
      {
         var _loc3_:Collectable = null;
         var _loc2_:String = param1[3];
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            _loc3_ = this.map.getCollectableManager().getCollectable(_loc2_);
            this.map.getFireworksManager().showFirework(_loc3_.getTypeID(),_loc3_.clip.x,_loc3_.clip.y);
            this.map.getCollectableManager().removeCollectable(_loc2_);
         }
      }
      
      private function assembleFireworksIgniteGroup(param1:Array) : void
      {
         var _loc3_:String = null;
         var _loc4_:Collectable = null;
         var _loc2_:int = 3;
         while(_loc2_ < param1.length)
         {
            _loc3_ = param1[_loc2_];
            this.map = this.main.screenManager.map;
            if(this.map != null)
            {
               _loc4_ = this.map.getCollectableManager().getCollectable(_loc3_);
               this.map.getFireworksManager().showFirework(_loc4_.getTypeID(),_loc4_.clip.x,_loc4_.clip.y);
               this.map.getCollectableManager().removeCollectable(_loc3_);
            }
            _loc2_++;
         }
      }
      
      private function assembleIndependenceDayMode(param1:Array) : void
      {
         Settings.fireworksModeIndependenceDay = Boolean(int(param1[3]));
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            this.map.getFireworksManager().updateColorsHashmap();
         }
      }
      
      private function assembleInitScoreboard(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         var _loc4_:int = int(param1[5]);
         var _loc5_:int = int(param1[6]);
         var _loc6_:int = int(param1[7]);
         this.main.getGuiManager().createSpaceballScoreboard([_loc2_,_loc3_,_loc4_]);
         this.main.getGuiManager().setSpaceballSpeed(_loc6_,_loc5_);
      }
      
      private function assembleSetScore(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         var _loc4_:int = int(param1[5]);
         this.main.getGuiManager().updateScoreboard(SimpleWindow.WINDOW_CLASS_SPACEBALL,SimpleContainer.CLASS_SPACEBALL,_loc2_,_loc3_);
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            this.map.portalManager.playPortalAnimation(_loc4_,true);
         }
      }
      
      private function assembleSetSpeed(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         this.main.getGuiManager().setSpaceballSpeed(_loc2_,_loc3_);
      }
      
      private function assembleInitInvasionScoreboard(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         var _loc4_:int = int(param1[5]);
         var _loc5_:int = int(param1[6]);
         this.main.getGuiManager().createInvasionScoreboard([_loc2_,_loc3_,_loc4_]);
         this.main.getGuiManager().setInvasionWave(_loc5_);
      }
      
      private function assembleSetInvasionScore(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         var _loc3_:int = int(param1[4]);
         this.main.getGuiManager().updateScoreboard(SimpleWindow.WINDOW_CLASS_INVASION,SimpleContainer.CLASS_INVASION,_loc2_,_loc3_);
      }
      
      private function assembleSetInvasionWave(param1:Array) : void
      {
         var _loc2_:int = int(param1[3]);
         this.main.getGuiManager().setInvasionWave(_loc2_);
      }
      
      private function assembleCtb(param1:Array) : void
      {
         this.map = this.main.screenManager.map;
         if(this.map != null)
         {
            this.map.getCtbManager().parseCommands(param1);
         }
      }
      
      private function assembleTeamDeathmatch(param1:Array) : void
      {
         this.main.getTDMManager().parseCommands(param1);
      }
      
      private function assembleSkillDesigns(param1:Array) : void
      {
         SkillsAssembly.getInstance().assembleSubCommand(param1);
      }
   }
}

