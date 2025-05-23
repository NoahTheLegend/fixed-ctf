// Standard menu player controls

#include "EmotesCommon.as"
#include "StandardControlsCommon.as"

bool zoomModifier = false; // decides whether to use the 3 zoom system or not
int zoomModifierLevel = 4; // for the extra zoom levels when pressing the modifier key
int zoomLevel = 1; // we can declare a global because this script is just used by myPlayer

void onInit(CBlob@ this)
{
	this.set_s32("tap_time", getGameTime());
	CBlob@[] blobs;
	this.set("pickup blobs", blobs);
	this.set_u16("hover netid", 0);
	this.set_bool("release click", false);
	this.set_bool("can button tap", true);
	this.addCommandID("pickup");
	this.addCommandID("putinheld");
	this.addCommandID("getout");
	this.addCommandID("detach");
	this.addCommandID("switch");

	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";

	//add to the sprite
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.AddScript("StandardControls.as");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (!isServer()) return;

	if (cmd == this.getCommandID("putinheld"))
	{
		CPlayer@ callerp = getNet().getActiveCommandPlayer();
		if (callerp is null) return;

		CBlob@ caller = callerp.getBlob();
		if (caller is null) return;
		if (caller !is this) return;
		if (caller.isInInventory()) return;
		if (caller.isAttached()) return;

		CBlob@ held = this.getCarriedBlob();
		if (held is null) return;

		putInHeld(caller);
	}
	else if (cmd == this.getCommandID("pickup"))
	{
		CPlayer@ callerp = getNet().getActiveCommandPlayer();
		if (callerp is null) return;

		CBlob@ caller = callerp.getBlob();
		if (caller is null) return;
		if (caller !is this) return;
		if (caller.isInInventory()) return;
		if (caller.isAttached()) return;

		u16 pickedup_id;
		if (!params.saferead_u16(pickedup_id)) return;

		CBlob@ pickedup = getBlobByNetworkID(pickedup_id);
		if (pickedup is null) return;

		if (!pickedup.canBePickedUp(caller)) return;

		if (pickedup.isAttached()) return;

		caller.server_Pickup(pickedup);
	}
	else if (cmd == this.getCommandID("detach"))
	{
		CPlayer@ callerp = getNet().getActiveCommandPlayer();
		if (callerp is null) return;

		CBlob@ caller = callerp.getBlob();
		if (caller is null) return;
		if (caller !is this) return;

		u16 attached_id;
		if (!params.saferead_u16(attached_id)) return;

		CBlob@ attached = getBlobByNetworkID(attached_id);
		if (attached is null) return;
		
		if (!this.isAttachedTo(attached)) return;

		this.server_DetachFrom(attached);
	}
	else if (cmd == this.getCommandID("getout"))
	{
		CBlob@ inv = this.getInventoryBlob();
		if (inv is null) return;

		CPlayer@ callerp = getNet().getActiveCommandPlayer();
		if (callerp is null) return;

		CBlob@ caller = callerp.getBlob();
		if (caller is null) return;

		if (caller !is this) return;

		inv.server_PutOutInventory(this);
	}
}

bool putInHeld(CBlob@ owner)
{
	if (owner is null) return false;

	CBlob@ held = owner.getCarriedBlob();
	if (held is null) return false;

	return owner.server_PutInInventory(held);
}

bool ClickGridMenu(CBlob@ this, int button)
{
	CGridMenu @gmenu;
	CGridButton @gbutton;

	if (this.ClickGridMenu(button, gmenu, gbutton))   // button gets pressed here - thing get picked up
	{
		if (gmenu !is null)
		{
			// if (gmenu.getName() == this.getInventory().getMenuName() && gmenu.getOwner() !is null)
			{
				if (gbutton is null)    // carrying something, put it in
				{
					client_PutInHeld(this);
				}
				else // take something
				{
					// handled by button cmd   // hardcoded still :/
				}
			}
			return true;
		}
	}

	return false;
}

void ButtonOrMenuClick(CBlob@ this, Vec2f pos, bool clear, bool doClosestClick)
{
	if (!ClickGridMenu(this, 0))
		if (this.ClickInteractButton())
		{
			clear = false;
		}
		else if (doClosestClick)
		{
			if (this.ClickClosestInteractButton(pos, this.getRadius() * 1.0f))
			{
				this.ClearButtons();
				clear = false;
			}
		}

	if (clear)
	{
		this.ClearButtons();
		this.ClearMenus();
	}
}

void onTick(CBlob@ this)
{
	if (getCamera() is null)
	{
		return;
	}
	ManageCamera(this);

	CControls@ controls = getControls();

	// use menu

	if (this.isKeyJustPressed(key_use))
	{
		Tap(this);
		this.set_bool("can button tap", !getHUD().hasMenus());
		this.ClearMenus();
		this.ShowInteractButtons();
		this.set_bool("release click", true);
	}
	else if (this.isKeyJustReleased(key_use))
	{
		if (this.get_bool("release click"))
		{
			CBlob@ carry = this.getCarriedBlob();
			ButtonOrMenuClick(this, carry !is null? carry.getPosition() : this.getPosition(),
							  true, isTap(this) && this.get_bool("can button tap"));
		}

		this.ClearButtons();
	}

	CBlob @carryBlob = this.getCarriedBlob();


	// bubble menu

	if (this.isKeyJustPressed(key_bubbles))
	{
		Tap(this);
	}

	// taunt menu

	if (this.isKeyJustPressed(key_taunts))
	{
		Tap(this);
	}

	/*else dont use this cause menu won't be release/clickable
	if (this.isKeyJustReleased(key_bubbles))
	{
	    this.ClearBubbleMenu();
	} */

	// in crate

	if (this.isInInventory())
	{
		if (this.isKeyJustPressed(key_pickup) && isClient())
		{
			CBlob@ invblob = this.getInventoryBlob();
			// Use the inventoryblob command if it has one (crate for example)
			if (invblob.hasCommandID("getout"))
			{
				invblob.SendCommand(invblob.getCommandID("getout"));
			}
			else
			{
				this.SendCommand(this.getCommandID("getout"));
			}
		}

		return;
	}

	// no more stuff possible while in crate...

	// inventory menu

	if (this.getInventory() !is null && this.getTickSinceCreated() > 10)
	{
		if (this.isKeyJustPressed(key_inventory))
		{
			Tap(this);
			this.set_bool("release click", true);
			// this.ClearMenus();

			//  Vec2f center =  getDriver().getScreenCenterPos(); // center of screen
			Vec2f center = controls.getMouseScreenPos();
			if (this.exists("inventory offset"))
			{
				this.CreateInventoryMenu(center + this.get_Vec2f("inventory offset"));
			}
			else
			{
				this.CreateInventoryMenu(center);
			}

			//controls.setMousePosition( center );
		}
		else if (this.isKeyJustReleased(key_inventory))
		{
			u8 minimum_ticks = 7;

			if (isTap(this, minimum_ticks))     // tap - put thing in inventory
			{
                CInventory@ inv = this.getInventory();
                if (inv is null) return;

				CBlob@ held = this.getCarriedBlob();
                bool inv_full = inv.isFull();
                bool can_put = !inv_full;

                if (inv_full && held !is null && held.getMaxQuantity() > 1)
                {
                    for (int i = 0; i < inv.getItemsCount(); i++)
                    {
                        CBlob@ item = inv.getItem(i);
                        if (item is null) continue;
                        if (item.getMaxQuantity() <= 1) continue;
                        if (item.getQuantity() == item.getMaxQuantity()) continue;
						if (item.hasTag("temp blob")) continue;

                        if (item.getName() == held.getName())
                            can_put = true;
                    }
                }

				if (held !is null && can_put)
				{
					this.SendCommand(this.getCommandID("putinheld"));
				}
				else
				{
                    if (this.getName() == "builder")
                    {

                        if (held !is null && held.hasTag("temp blob"))
                            held.server_Die();
                        else
                            this.set_TileType("buildtile", 0);
                    }

					ControlsCycle@ onCycle;
					if (this.get("onCycle handle", @onCycle))
					{
						CBitStream params;
						params.write_u16(this.getNetworkID());
						params.ResetBitIndex();

						onCycle(params);
					}
				}

				this.ClearMenus();
				return;
			}
			else // click inventory
			{
				if (this.get_bool("release click"))
				{
					ClickGridMenu(this, 0);
				}

				if (!this.hasTag("dont clear menus"))
				{
					this.ClearMenus();
				}
				else
				{
					this.Untag("dont clear menus");
				}
			}
		}
	}

	// release action1 to click buttons

	if (getHUD().hasButtons())
	{
		if ((this.isKeyJustPressed(key_action1) /*|| controls.isKeyJustPressed(KEY_LBUTTON)*/) && !this.isKeyPressed(key_pickup))
		{
			ButtonOrMenuClick(this, this.getAimPos(), false, true);
			this.set_bool("release click", false);
		}
	}

	// clear grid menus on move

	if (!this.isKeyPressed(key_inventory) &&
	        (this.isKeyJustPressed(key_left) || this.isKeyJustPressed(key_right) || this.isKeyJustPressed(key_up) ||
	         this.isKeyJustPressed(key_down) || this.isKeyJustPressed(key_action2) || this.isKeyJustPressed(key_action3))
	   )
	{
		this.ClearMenus();
	}

	//if (this.isKeyPressed(key_action1))
	//{
	//  //server_DropCoins( this.getAimPos(), 100 );
	//  CBlob@ mat = server_CreateBlob( "cata_rock", 0, this.getAimPos());
	//}

	// keybinds

	if (controls.ActionKeyPressed(AK_BUILD_MODIFIER))
	{
		EKEY_CODE[] keybinds = { KEY_KEY_1, KEY_KEY_2, KEY_KEY_3, KEY_KEY_4, KEY_KEY_5, KEY_KEY_6, KEY_KEY_7, KEY_KEY_8, KEY_KEY_9, KEY_KEY_0 };

		// loop backwards so leftmost keybinds have priority
		for (int i = keybinds.size() - 1; i >= 0; i--)
		{
			if (controls.isKeyJustPressed(keybinds[i]))
			{
				ControlsSwitch@ onSwitch;
				if (this.get("onSwitch handle", @onSwitch))
				{
					CBitStream params;
					params.write_u16(this.getNetworkID());
					params.write_u8(i);
					params.ResetBitIndex();

					onSwitch(params);
				}
			}
		}
	}
}

// show dots on chat

void onDie(CBlob@ this)
{
	set_emote(this, "");
}

// CAMERA

void onInit(CSprite@ this)
{
	//backwards compat - tag the blob if we're assigned to the sprite too
	//so if it's not there, the blob can adjust the camera at 30fps at least
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	blob.Tag("60fps_camera");
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null || !blob.isMyPlayer()) return;
	//do 60fps camera
	AdjustCamera(blob, true);
}

void AdjustCamera(CBlob@ this, bool is_in_render)
{
	CCamera@ camera = getCamera();
	f32 zoom = camera.targetDistance;

	f32 zoomSpeed = 0.1f;
	if (is_in_render)
	{
		zoomSpeed *= getRenderApproximateCorrectionFactor();
	}

	f32 minZoom = 0.5f; // TODO: make vars
	f32 maxZoom = 2.0f;

	f32 zoom_target = 1.0f;

	if (zoomModifier) 
	{
		switch (zoomModifierLevel) 
		{
			case 0:	zoom_target = 0.5f; zoomLevel = 0; break;
			case 1: zoom_target = 0.5625f; zoomLevel = 0; break;
			case 2: zoom_target = 0.625f; zoomLevel = 0; break;
			case 3: zoom_target = 0.75f; zoomLevel = 0; break;
			case 4: zoom_target = 1.0f; zoomLevel = 1; break;
			case 5: zoom_target = 1.5f; zoomLevel = 1; break;
			case 6: zoom_target = 2.0f; zoomLevel = 2; break;
		}
	} 
	else 
	{
		switch (zoomLevel) 
		{
			case 0: zoom_target = 0.5f; zoomModifierLevel = 0; break;
			case 1: zoom_target = 1.0f; zoomModifierLevel = 4; break;
			case 2:	zoom_target = 2.0f; zoomModifierLevel = 6; break;
		}
	}

	if (zoom > zoom_target)
	{
		zoom = Maths::Max(zoom_target, zoom - zoomSpeed);
	}
	else if (zoom < zoom_target)
	{
		zoom = Maths::Min(zoom_target, zoom + zoomSpeed);
	}

	camera.targetDistance = zoom;
}

void ManageCamera(CBlob@ this)
{
	CCamera@ camera = getCamera();
	CControls@ controls = this.getControls();

	// mouse look & zoom
	if ((getGameTime() - this.get_s32("tap_time") > 5) && controls !is null)
	{
		if (controls.isKeyJustPressed(controls.getActionKeyKey(AK_ZOOMOUT)))
		{
			zoomModifier = controls.isKeyPressed(KEY_LCONTROL);

			zoomModifierLevel = Maths::Max(0, zoomModifierLevel - 1);
			zoomLevel = Maths::Max(0, zoomLevel - 1);

			Tap(this);
		}
		else  if (controls.isKeyJustPressed(controls.getActionKeyKey(AK_ZOOMIN)))
		{
			zoomModifier = controls.isKeyPressed(KEY_LCONTROL);

			zoomModifierLevel = Maths::Min(6, zoomModifierLevel + 1);
			zoomLevel = Maths::Min(2, zoomLevel + 1);

			Tap(this);
		}
	}

	if (!this.hasTag("60fps_camera"))
	{
		AdjustCamera(this, false);
	}

	f32 zoom = camera.targetDistance;
	bool fixedCursor = true;
	if (zoom < 1.0f)  // zoomed out
	{
		camera.mousecamstyle = 1; // fixed
	}
	else
	{
		// gunner
		if (this.isAttachedToPoint("GUNNER"))
		{
			camera.mousecamstyle = 2;
		}
		else if (g_fixedcamera) // option
		{
			camera.mousecamstyle = 1; // fixed
		}
		else
		{
			camera.mousecamstyle = 2; // soldatstyle
		}
	}

	// camera
	camera.mouseFactor = 0.5f; // doesn't affect soldat cam
}
