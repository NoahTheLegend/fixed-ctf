#define CLIENT_ONLY

const int endTime1 = getTicksASecond() * 5;
const int endTime2 = getTicksASecond() * 15;
const string changes = "Changes:\n\n"+
				" - Reverted quarry without output reduction over time.\n\n"+
				" - Knight attacks in an arc instead of ray again.\n\n"+
				" - Reverted old catapult force.\n\n"+
				" - Saws destroy bombs instead of whirling them.\n\n"+
                " - Old costs and more maps.\n\n"+
                " - Most of the current vanilla bugs are fixed.";
int time = 0;

void onInit(CRules@ this)
{
	time = 0;

    client_AddToChat(changes, color_black);
}

void onReload(CRules@ this)
{
    time = 0;
}

void onTick(CRules@ this)
{
    if (time <= endTime2) {
        CControls@ controls = getControls();
        if (controls is null) return;
        
        if (controls.isKeyJustPressed(KEY_RBUTTON)) {
            time = endTime2 + 1;
        }
    }

    time++;
}

void onRender( CRules@ this )
{
	bool draw = false;
	Vec2f ul, lr;
	string text = "";

	ul = Vec2f( 30, 3*getScreenHeight()/4 );

    if (time < endTime1) {
        text = "Welcome to Retro CTF!\n\n"+"Right click to dismiss this message.";
        
		Vec2f size;
		GUI::GetTextDimensions(text, size);
		lr = ul + size;
		draw = true;
    }
	else if (time < endTime2) {
		text = changes;

		Vec2f size;
		GUI::GetTextDimensions(text, size);
		lr = ul + size;
		lr.y -= 32.0f;
		draw = true;
	}

	if(draw)
	{
		f32 wave = Maths::Sin(getGameTime() / 10.0f) * 2.0f;
		ul.y += wave;
		lr.y += wave;
		GUI::DrawButtonPressed( ul - Vec2f(10,10), lr + Vec2f(10,10) );
		GUI::DrawText( text, ul, SColor(0xffffffff) );
	}
}