#ifndef UI_HC
#define UI_HC

#include "Controls"
#include "Draw"
#include "Mob"
#include "Slider"
#include "GameInput"
/*
#include "Px/CursorReg"
#include "Px/CursorBuy"
#include "Px/StatusBar"
#include "Px/InventoryScreen"
#include "Px/CloseButtonHover"
#include "Px/InventoryButtonOpen"
#include "Px/TradeScreen"
#include "Px/Buy"
#include "Px/BuyHover"
#include "Px/Sell"
#include "Px/SellHover"
*/
#define TOOLBAR_SLOTS 8
#define TOOLBAR_X1 16
#define TOOLBAR_X2 TOOLBAR_X1+608
#define TOOLBAR_Y1 448
#define TOOLBAR_Y2 TOOLBAR_Y1+24
#define TOOLBAR_INV_X1 TOOLBAR_X1+585
#define TOOLBAR_INV_X2 TOOLBAR_INV_X1+20
#define TOOLBAR_INV_Y1 TOOLBAR_Y1+2
#define TOOLBAR_INV_Y2 TOOLBAR_INV_Y1+20
#define TOOLBAR_SLOT_X TOOLBAR_X1+122
#define TOOLBAR_SLOT_Y TOOLBAR_Y1+4
#define TOOLBAR_MONEY_X TOOLBAR_X1+412
#define TOOLBAR_MONEY_Y TOOLBAR_Y1+4
#define TOOLBAR_WEIGHT_X TOOLBAR_X1+317
#define TOOLBAR_WEIGHT_Y TOOLBAR_Y1+4

#define TRADE_X 128
#define TRADE_Y 128
#define TRADE_X2 TRADE_X+360
#define TRADE_Y2 TRADE_Y+130
#define TRADE_SLIDER_X TRADE_X+77
#define TRADE_SLIDER_Y TRADE_Y+109
#define TRADE_PSLOT_X TRADE_X+5
#define TRADE_SLOT_Y TRADE_Y+5
#define TRADE_SLOTS_Y1 TRADE_Y+3
#define TRADE_SLOTS_Y2 TRADE_SLOTS_Y1+41
#define TRADE_VSLOT_X TRADE_X+185
#define TRADE_PSLOTS_X1 TRADE_X+3
#define TRADE_PSLOTS_X2 TRADE_PSLOTS_X1+173
#define TRADE_VSLOTS_X1 TRADE_X+183
#define TRADE_VSLOTS_X2 TRADE_VSLOTS_X1+173
#define TRADE_BUTTON_W 65
#define TRADE_BUTTON_H 24
#define TRADE_BUTTON_Y TRADE_Y+64
#define TRADE_BUTTON_Y2 TRADE_BUTTON_Y+TRADE_BUTTON_H
#define TRADE_BUY_X TRADE_X+287
#define TRADE_BUY_X2 TRADE_BUY_X+TRADE_BUTTON_W
#define TRADE_SELL_X TRADE_X+8
#define TRADE_SELL_X2 TRADE_SELL_X+TRADE_BUTTON_W
#define TRADE_CLOSE_X1 TRADE_X+341
#define TRADE_CLOSE_X2 TRADE_CLOSE_X1+16
#define TRADE_CLOSE_Y1 TRADE_Y+111
#define TRADE_CLOSE_Y2 TRADE_CLOSE_Y1+16

#define INV_X 230
#define INV_Y 128
#define INV_X2 INV_X+180
#define INV_Y2 INV_Y+122
#define INV_SLOT_X INV_X+5
#define INV_SLOT_Y INV_Y+5
#define INV_SLOT_W 20
#define INV_SLOT_H 20
#define INV_SLOT_COLUMN 8
#define INV_SLOT_ROW 2
#define INV_SLOT_ROW_OFF 22
#define INV_NAME_X INV_X+4
#define INV_NAME_Y INV_Y+46
#define INV_PRICE_X INV_NAME_X+20
#define INV_PRICE_Y INV_NAME_Y+18
#define INV_WEIGHT_X INV_PRICE_X
#define INV_WEIGHT_Y INV_PRICE_Y+18
#define INV_CLOSE_X1 INV_X+161
#define INV_CLOSE_X2 INV_CLOSE_X1+16
#define INV_CLOSE_Y1 INV_Y+103
#define INV_CLOSE_Y2 INV_CLOSE_Y1+16

#define UI_INV_ENABLED 1
#define UI_TRADE_ENABLED 2
#define UI_INSTRUCTIONS_ENABLED 4
#define UI_ESCMENU_ENABLED 8

#define VENDOR_ITEMS 4

#define BUTTON_NORMAL   0
#define BUTTON_HOVER    1
#define BUTTON_DISABLED 2
#define BUTTON_CLICKED  3

class Button {
  CD2I32 pos;
  CD2I32 size;
  CD2I32 textPos;
  U8 *str;
  U8 colorActive;
  U8 colorTrimActive;
  U8 colorBorderActive;
  U8 color;
  U8 colorTrim;
  U8 colorBorder;
  U8 colorHover;
  U8 colorTrimHover;
  U8 colorBorderHover;
  U8 state;
};

I32 gVendorInv[VENDOR_ITEMS] = {
  ITEM_PICKAXE,
  ITEM_LADDER,
  ITEM_COOLER,
  ITEM_GUN,
};

class Toolbar {
  U8 coinText[12];
  PxData *slotsPx[TOOLBAR_SLOTS];
  Bool invHover;
};

class InventoryUI {
  ItemInv mouseItem;
};

class TradeUI {
  PxData *buttonBuy;
  PxData *buttonSell;
  Slider slider;
  Bool selVendor;
};

class EscMenuUI {
  Button buttonMainMenu;
};

class UI {
  F64 lookRot;
  CD2 equipPosOffset;
  CD2I32 mouse;
  CD2I32 selPos;
  CD2I32 hoverPos;
  I32 selID;
  I32 hoverID;
  PxData *cursor;
  Toolbar toolbar;
  InventoryUI inv;
  TradeUI trade;
  EscMenuUI escMenu;
  U8 flags;
  Bool mouseConsumed;
  Bool closeHover;
};

public U0 itoa(U8* dst, I64 num) {
  I64 i = 0;
  Bool neg = FALSE;
  if (num == 0) {
    dst[0] = '0';
    dst[1] = '\0';
    return;
  }
  if (num < 0) {
    neg = TRUE;
    num = -num;
  }
  do {
    I64 rem = num%10;
    U8 c;
    if (rem > 9)
      c = rem-10+'a';
    else
      c = rem+'0';
    dst[i++] = c;
    num /= 10;
  } while (num != 0);
  if (neg)
    dst[i++] = '-';
  dst[i--] = '\0';

  // Reverse String
  I64 ii;
  for (ii=0; ii<i; ii++, i--)
    SwapU8(&dst[i], &dst[ii]);
}

public U0 LineHF0(CDC *dc, I32 x, I32 y, I32 l, U8 color) {
  I32 i;
  I32 yy = y*dc->width_internal;
  for (i=x; i<x+l; i++)
    dc->body[i+yy] = color;
}

public U0 LineVF0(CDC *dc, I32 x, I32 y, I32 l, U8 color) {
  I32 i;
  for (i=y; i<y+l; i++)
    dc->body[i*dc->width_internal+x] = color;
}

public U0 LineHF1(CDC *dc, I32 x, I32 y, I32 l, U8 color) {
  // Clip MinX
  if (x < 0) {
    l += x;
    x = 0;
  }
  // Clip MaxX
  I32 i = x+l;
  if (i >= 640)
    l -= i - 640;

  I32 yy = y*dc->width_internal;
  for (i=x; i<x+l; i++)
    dc->body[i+yy] = color;
}

public U0 LineVF1(CDC *dc, I32 x, I32 y, I32 l, U8 color) {
  // Clip MinY
  if (y < 8) {
    l += y - 8;
    y = 8; 
  }
  // Clip MaxY
  I32 i = y+l;
  if (i >= 480)
    l -= i - 480;

  for (i=y; i<y+l; i++)
    dc->body[i*dc->width_internal+x] = color;
}

public U0 RecBorder(CDC* dc, I32 x, I32 y, I32 w, I32 h, U8 color) {
  y += 8;
  LineHF0(dc, x, y, w, color);
  LineHF0(dc, x, y+h-1, w, color);
  LineVF0(dc, x, y+1, h-2, color);
  LineVF0(dc, x+w-1, y+1, h-2, color);
}

// Specifically for tile highlighting, doesn't clip in all situations
public U0 RecBorderClip(CDC* dc, I32 x, I32 y, I32 w, I32 h, U8 color) {
  y += 8;
  if (y >= 8)
    LineHF1(dc, x, y, w, color);
  if (y < 480)
    LineHF1(dc, x, y+h-1, w, color);
  if (x >= 0)
    LineVF1(dc, x, y+1, h-2, color);
  if (x+w-1 < 640)
    LineVF1(dc, x+w-1, y+1, h-2, color);
}

U0 ToolbarUpdate(Toolbar *toolbar, Player *mob) {
  I64 i, id;
  for (i=0; i<TOOLBAR_SLOTS; i++) {
    id = mob->inv.items[i].id;
    if (id >= 0) {
      toolbar->slotsPx[i] = gItems[id].pxInv;
    } else {
      toolbar->slotsPx[i] = NULL;
    }
  }
  itoa(toolbar->coinText, mob->money);
}

U0 InventoryOpen(UI *ui) {
  ui->flags = UI_INV_ENABLED;
  ui->hoverID = -1;
  ui->closeHover = FALSE;
}

U0 InventoryClose(UI *ui, World *w) {
  ui->flags = 0;
  if (ui->inv.mouseItem.id >= 0) {
    I32 xMod = 32;
    F64 xVel = 64;
    if (w->player.flags&PFLAG_FACE_LEFT) {
      xMod = -16;
      xVel = -64;
    }
    ItemAdd(&w->items, ui->inv.mouseItem.id, ui->inv.mouseItem.qty,
            w->player.pos.x+xMod, w->player.pos.y, xVel, 0);
    ui->inv.mouseItem.id = -1;
  }
}

U0 ToolbarHandle(UI *ui, Controls *ctrl, World *w) {
  if (ui->mouse.x >= TOOLBAR_X1 && ui->mouse.x < TOOLBAR_X2 && ui->mouse.y >= TOOLBAR_Y1 && ui->mouse.y < TOOLBAR_Y2) {
    ui->mouseConsumed = TRUE;
    if (ui->mouse.x >= TOOLBAR_INV_X1 && ui->mouse.x < TOOLBAR_INV_X2 && ui->mouse.y >= TOOLBAR_INV_Y1 && ui->mouse.y < TOOLBAR_INV_Y2) {
      ui->toolbar.invHover = TRUE;
      if (ctrl->mLDown) {
        if (ui->flags&UI_INV_ENABLED) {
          InventoryClose(ui, w);
        } else {
          InventoryOpen(ui);
        }
      }
    } else {
      ui->toolbar.invHover = FALSE;
    }
  } else {
    ui->toolbar.invHover = FALSE;
  }
}

U0 UIInit(UI *ui, Player *mob) {
  ui->cursor = &CursorReg;
  ui->toolbar.invHover = FALSE;
  ToolbarUpdate(&ui->toolbar, mob);
  ui->selID = -1;
  ui->hoverID = -1;
  ui->inv.mouseItem.id = -1;
  ui->mouseConsumed = FALSE;
  ui->flags = 0;
  ui->closeHover = FALSE;

  // Trade Init
  SliderInit(&ui->trade.slider, TRADE_SLIDER_X, TRADE_SLIDER_Y, 128, 8, 0);
}

U0 ToolbarDraw(CDC *dc, UI *ui, F64 health, I32 selSlot) {
  I32 i;
  PxBlot(dc->body, &StatusBar, TOOLBAR_X1, TOOLBAR_Y1);
  //DrawText(dc->body, &fontSmall, &ui->toolbar.coinText, 172, 455);
  DrawText(dc->body, &fontBig, ui->toolbar.coinText, TOOLBAR_MONEY_X, TOOLBAR_MONEY_Y);

  // Draw Items
  for (i=0; i<TOOLBAR_SLOTS; i++) {
    if(ui->toolbar.slotsPx[i])
      PxBlot(dc->body, ui->toolbar.slotsPx[i], TOOLBAR_SLOT_X+22*i, TOOLBAR_SLOT_Y);
  }
  if (ui->toolbar.invHover) {
    if (!ui->flags&UI_INV_ENABLED)
      PxBlot(dc->body, &InventoryButtonOpen, TOOLBAR_INV_X1+1, TOOLBAR_INV_Y1);
  } else if (ui->flags&UI_INV_ENABLED) {
    PxBlot(dc->body, &InventoryButtonOpen, TOOLBAR_INV_X1+1, TOOLBAR_INV_Y1);
  }
  RecBorder(dc, (TOOLBAR_SLOT_X-1)+22*selSlot, TOOLBAR_SLOT_Y-1, 18, 18, SWEET_GREEN);

  // Draw Health
  #define HEALTH_X 42
  #define HEALTH_Y 453+8
  if (health > 0) {
    I32 healthBarW = health / 100 * 90 - 1;
    LineH(dc->body, HEALTH_X+1, HEALTH_X+healthBarW-1, HEALTH_Y, SWEET_ORANGE);
    LineH(dc->body, HEALTH_X+1, HEALTH_X+healthBarW-1, HEALTH_Y+13, SWEET_ORANGE);
    LineV(dc->body, HEALTH_X, HEALTH_Y+1, HEALTH_Y+12, SWEET_ORANGE);
    LineV(dc->body, HEALTH_X+healthBarW, HEALTH_Y+1, HEALTH_Y+12, SWEET_ORANGE);
    CD2I32 pos, size;
    pos.x = HEALTH_X+1;
    pos.y = HEALTH_Y+1;
    size.x = healthBarW-1;
    size.y = 12;
    DrawRect(dc->body, pos, size, SWEET_RED);
  }
}

U0 InventoryDraw(CDC *dc, UI *ui, Inventory *inv) {
  PxBlot(dc->body, &InventoryScreen, INV_X, INV_Y);
  U8 strBuf[16];
  I32 row;
  for (row=0; row<INV_SLOT_ROW; row++) {
    I32 column;
    for (column=0; column<INV_SLOT_COLUMN; column++) {
      I32 slot = column+row*INV_SLOT_COLUMN;
      I32 y = INV_SLOT_Y+INV_SLOT_ROW_OFF*row;
      I32 id = inv->items[slot].id;
      if (id >= 0) {
        PxBlot(dc->body, gItems[id].pxInv, INV_SLOT_X+22*column, y);
        itoa(strBuf, inv->items[slot].qty);
        DrawText(dc->body, &fontSmall, strBuf, INV_SLOT_X+22*column, y+8);
      }
    }
  }
  if (ui->hoverID >= 0) {
    RecBorder(dc, ui->hoverPos.x, ui->hoverPos.y, INV_SLOT_W, INV_SLOT_H, SWEET_BLUE);
    id = inv->items[ui->hoverID].id;
    if (id >= 0) {
      DrawText(dc->body, &fontBig, gItems[id].name, INV_NAME_X, INV_NAME_Y);
      if (inv->items[ui->hoverID].qty == 1)
        itoa(strBuf, gItems[id].price);
      else
        StrPrint(strBuf, "%d (%d)", gItems[id].price, gItems[id].price*inv->items[ui->hoverID].qty);
      DrawText(dc->body, &fontBig, strBuf, INV_PRICE_X, INV_PRICE_Y);
      itoa(strBuf, gItems[id].weight);
      DrawText(dc->body, &fontBig, strBuf, INV_WEIGHT_X, INV_WEIGHT_Y);
    }
  }

  if (ui->closeHover)
    PxBlot(dc->body, &CloseButtonHover, INV_CLOSE_X1+1, INV_CLOSE_Y1+1);
}

U0 InventoryHandle(UI *ui, Inventory *inv, Controls *ctrl, World *w) {
  if (ui->mouse.x >= INV_X && ui->mouse.x < INV_X2 && ui->mouse.y >= INV_Y && ui->mouse.y < INV_Y2) {
    ui->mouseConsumed = TRUE;
    I32 row;
    for (row=0; row<INV_SLOT_ROW; row++) {
      I32 column;
      for (column=0; column<INV_SLOT_COLUMN; column++) {
        I32 slot = column+row*INV_SLOT_COLUMN;
        I32 x1 = INV_SLOT_X-2+22*column;
        I32 x2 = x1 + INV_SLOT_W;
        I32 y1 = (INV_SLOT_Y-2)+INV_SLOT_ROW_OFF*row;
        I32 y2 = y1 + INV_SLOT_H;
        if (ui->mouse.x >= x1 && ui->mouse.x < x2 && ui->mouse.y >= y1 && ui->mouse.y < y2) {
          ui->hoverID = slot;
          ui->hoverPos.x = x1;
          ui->hoverPos.y = y1;
          ItemInv tmpItem;
          if (ctrl->mLDown) {
            if (ui->inv.mouseItem.id >= 0) {
              if (ui->inv.mouseItem.id == inv->items[slot].id) { // Merge Full Stack
                U16 qty = ui->inv.mouseItem.qty + inv->items[slot].qty;
                ui->inv.mouseItem.qty = 0;
                if (qty > gItems[inv->items[slot].id].stackSize) {
                  ui->inv.mouseItem.qty = qty - gItems[inv->items[slot].id].stackSize;
                  inv->items[slot].qty = gItems[inv->items[slot].id].stackSize;
                } else {
                  inv->items[slot].qty = qty;
                  ui->inv.mouseItem.id = -1;
                }
              } else if (inv->items[slot].id >= 0) { // Swap Full Stack
                MemCpy(&tmpItem, &inv->items[slot], sizeof(ItemInv));
                MemCpy(&inv->items[slot], &ui->inv.mouseItem, sizeof(ItemInv));
                MemCpy(&ui->inv.mouseItem, &tmpItem, sizeof(ItemInv));
              } else { // Insert Full Stack
                MemCpy(&inv->items[slot], &ui->inv.mouseItem, sizeof(ItemInv));
                ui->inv.mouseItem.id = -1;
              }
            } else if (inv->items[slot].id >= 0) { // Pickup Full Stack
              MemCpy(&ui->inv.mouseItem, &inv->items[slot], sizeof(ItemInv));
              inv->items[slot].id = -1;
            }
            ToolbarUpdate(&ui->toolbar, &w->player);
            UpdatePxUse(&w->player);
          } else if (ctrl->mRDown) {
            if (ui->inv.mouseItem.id >= 0) {
              if (ui->inv.mouseItem.id == inv->items[slot].id) { // Merge One
                if (++inv->items[slot].qty > gItems[inv->items[slot].id].stackSize) {
                  inv->items[slot].qty = gItems[inv->items[slot].id].stackSize;
                } else if (--ui->inv.mouseItem.qty <= 0) {
                  ui->inv.mouseItem.id = -1;
                }
              } else if (inv->items[slot].id >= 0) { // Swap Full Stack
                MemCpy(&tmpItem, &inv->items[slot], sizeof(ItemInv));
                MemCpy(&inv->items[slot], &ui->inv.mouseItem, sizeof(ItemInv));
                MemCpy(&ui->inv.mouseItem, &tmpItem, sizeof(ItemInv));
              } else { // Insert One
                MemCpy(&inv->items[slot], &ui->inv.mouseItem, sizeof(ItemInv));
                inv->items[slot].qty = 1;
                if (--ui->inv.mouseItem.qty <= 0)
                  ui->inv.mouseItem.id = -1;
              }
            } else if (inv->items[slot].id >= 0) { // Pickup Half Stack
              MemCpy(&ui->inv.mouseItem, &inv->items[slot], sizeof(ItemInv));
              ui->inv.mouseItem.qty = inv->items[slot].qty / 2;
              inv->items[slot].qty -= ui->inv.mouseItem.qty;
            }
            ToolbarUpdate(&ui->toolbar, &w->player);
            UpdatePxUse(&w->player);
          }
        }
      }
    }
    if (ui->mouse.x >= INV_CLOSE_X1 && ui->mouse.x < INV_CLOSE_X2 && ui->mouse.y >= INV_CLOSE_Y1 && ui->mouse.y < INV_CLOSE_Y2) {
      ui->closeHover = TRUE;
      if (ctrl->mLDown) {
        InventoryClose(ui, w);
        return;
      }
    } else {
      ui->closeHover = FALSE;
    }
  } else {
    ui->closeHover = FALSE;
  }
}

U0 TradeOpen(UI *ui) {
  ui->selID = -1;
  ui->hoverID = -1;
  ui->flags = UI_TRADE_ENABLED;
  ui->trade.buttonBuy = NULL;
  ui->trade.buttonSell = NULL;
  ui->trade.slider.bitActive = FALSE;
  SliderSet(&ui->trade.slider, 0, 0);
  ui->closeHover = FALSE;
}

U0 TradeClose(UI *ui) {
  ui->flags = 0;
}

U0 TradeHandle(UI *ui, Controls *ctrl, World *w) {
  if (ui->mouse.x >= TRADE_X && ui->mouse.x < TRADE_X2 && ui->mouse.y >= TRADE_Y && ui->mouse.y < TRADE_Y2) {
    ui->mouseConsumed = TRUE;
    I32 row, column, x1, y1, slot;
    if (ui->mouse.x >= TRADE_PSLOTS_X1 && ui->mouse.x < TRADE_PSLOTS_X2 && ui->mouse.y >= TRADE_SLOTS_Y1 && ui->mouse.y < TRADE_SLOTS_Y2) {
      for (row=0; row<INV_SLOT_ROW; row++) {
        for (column=0; column<INV_SLOT_COLUMN; column++) {
          slot = column+row*INV_SLOT_COLUMN;
          x1 = TRADE_PSLOT_X-2+22*column;
          y1 = (TRADE_SLOT_Y-2)+INV_SLOT_ROW_OFF*row;
          if (ui->mouse.x >= x1 && ui->mouse.x < x1+INV_SLOT_W && ui->mouse.y >= y1 && ui->mouse.y < y1+INV_SLOT_H) {
            ui->hoverID = slot;
            ui->hoverPos.x = x1;
            ui->hoverPos.y = y1;
            if (ui->selID < 0)
              ui->trade.selVendor = FALSE;
            if (ctrl->mLDown && w->player.inv.items[slot].id >= 0) {
              ui->trade.selVendor = FALSE;
              SliderSet(&ui->trade.slider, 0, w->player.inv.items[slot].qty);
              ui->selID = slot;
              ui->selPos.x = x1;
              ui->selPos.y = y1;
            }
          }
        }
      }
    } else if (ui->mouse.x >= TRADE_VSLOTS_X1 && ui->mouse.x < TRADE_VSLOTS_X2 && ui->mouse.y >= TRADE_SLOTS_Y1 && ui->mouse.y < TRADE_SLOTS_Y2) {
      for (row=0; row<INV_SLOT_ROW; row++) {
        for (column=0; column<INV_SLOT_COLUMN; column++) {
          slot = column+row*INV_SLOT_COLUMN;
          x1 = TRADE_VSLOT_X-2+22*column;
          y1 = (TRADE_SLOT_Y-2)+INV_SLOT_ROW_OFF*row;
          if (ui->mouse.x >= x1 && ui->mouse.x < x1+INV_SLOT_W && ui->mouse.y >= y1 && ui->mouse.y < y1+INV_SLOT_H) {
            ui->hoverID = slot;
            ui->hoverPos.x = x1;
            ui->hoverPos.y = y1;
            if (ui->selID < 0)
              ui->trade.selVendor = TRUE;
            if (ctrl->mLDown && slot < VENDOR_ITEMS) {
              ui->trade.selVendor = TRUE;
              SliderSet(&ui->trade.slider, 0, gItems[gVendorInv[slot]].stackSize);
              ui->selID = slot;
              ui->selPos.x = x1;
              ui->selPos.y = y1;
            }
          }
        }
      }
    }
    SliderHandle(&ui->trade.slider, ctrl);
    if (ui->mouse.x >= TRADE_CLOSE_X1 && ui->mouse.x < TRADE_CLOSE_X2 && ui->mouse.y >= TRADE_CLOSE_Y1 && ui->mouse.y < TRADE_CLOSE_Y2) {
      ui->closeHover = TRUE;
      if (ctrl->mLDown) {
        TradeClose(ui);
        return;
      }
    } else {
      ui->closeHover = FALSE;
    }
  } else {
    ui->closeHover = FALSE;
  }

  // Handle Buy/Sell Buttons
  ui->trade.buttonBuy = NULL;
  ui->trade.buttonSell = NULL;
  if (ui->trade.slider.val > 0 && ui->selID >= 0) {
    I32 price;
    if (ui->trade.selVendor) {
      price = gItems[gVendorInv[ui->selID]].price*ui->trade.slider.val;
      if (w->player.money >= price && InvAddCheck(&w->player.inv, gVendorInv[ui->selID], ui->trade.slider.val) == 0) { // TODO cache in handle
        ui->trade.buttonBuy = &Buy;
        if (ui->mouse.x >= TRADE_BUY_X && ui->mouse.x < TRADE_BUY_X2 && ui->mouse.y >= TRADE_BUTTON_Y && ui->mouse.y < TRADE_BUTTON_Y2) {
          ui->trade.buttonBuy = &BuyHover;
          if (ctrl->mLDown) {
            InvAdd(&w->player.inv, gVendorInv[ui->selID], ui->trade.slider.val);
            w->player.money -= price;
            ToolbarUpdate(&ui->toolbar, &w->player);
          }
        }
      }
    } else {
      ui->trade.buttonSell = &Sell;
      if (ui->mouse.x >= TRADE_SELL_X && ui->mouse.x < TRADE_SELL_X2 && ui->mouse.y >= TRADE_BUTTON_Y && ui->mouse.y < TRADE_BUTTON_Y2) {
        ui->trade.buttonSell = &SellHover;
        if (ctrl->mLDown) {
          price = gItems[w->player.inv.items[ui->selID].id].price*ui->trade.slider.val;
          w->player.money += price;
          InvRemFromSlot(&w->player.inv, ui->selID, ui->trade.slider.val);
          if (w->player.inv.items[ui->selID].id >= 0)
            SliderSet(&ui->trade.slider, 0, w->player.inv.items[ui->selID].qty);
          else {
            ui->selID = -1;
            SliderSet(&ui->trade.slider, 0, 0);
          }
          ToolbarUpdate(&ui->toolbar, &w->player);
        }
      }
    }
  }
}

U0 TradeDraw(CDC *dc, UI *ui, Inventory *inv) {
  PxBlot(dc->body, &TradeScreen, TRADE_X, TRADE_Y);
  SliderDraw(dc->body, &ui->trade.slider);

  // Draw Player Items
  U8 strBuf[16];
  I32 row, column, slot;
  for (row=0; row<INV_SLOT_ROW; row++) {
    for (column=0; column<INV_SLOT_COLUMN; column++) {
      slot = column+row*INV_SLOT_COLUMN;
      I32 y = TRADE_SLOT_Y+INV_SLOT_ROW_OFF*row;
      I32 id = inv->items[slot].id;
      if (id >= 0) {
        PxBlot(dc->body, gItems[id].pxInv, TRADE_PSLOT_X+22*column, y);
        itoa(strBuf, inv->items[slot].qty);
        DrawText(dc->body, &fontSmall, strBuf, TRADE_PSLOT_X+22*column, y+8);
      }
    }
  }

  // Draw Vendor Items
  slot = 0;
  for (row=0; row<INV_SLOT_ROW; row++) {
    for (column=0; column<INV_SLOT_COLUMN; column++) {
      PxBlot(dc->body, gItems[gVendorInv[slot]].pxInv, TRADE_VSLOT_X+22*column, TRADE_SLOT_Y+INV_SLOT_ROW_OFF*row);
      if (++slot >= VENDOR_ITEMS)
        goto endVendorItemDraw;
    }
  }
  endVendorItemDraw:

  // Draw Selection
  slot = ui->hoverID;
  if (ui->selID >= 0)
    slot = ui->selID;
  if (slot >= 0) {
    RecBorder(dc, ui->hoverPos.x, ui->hoverPos.y, INV_SLOT_W, INV_SLOT_H, SWEET_BLUE);
    if (ui->selID >= 0)
      RecBorder(dc, ui->selPos.x, ui->selPos.y, INV_SLOT_W, INV_SLOT_H, SWEET_RED);
    if (ui->trade.selVendor) {
      if (slot < VENDOR_ITEMS)
        id = gVendorInv[slot];
      else
        id = -1;
    } else {
      id = inv->items[slot].id;
    }
    if (id >= 0) {
      DrawText(dc->body, &fontBig, gItems[id].name, TRADE_X+78, TRADE_Y+50);
      if (ui->selID >= 0)
        StrPrint(strBuf, "%d (%d)", gItems[id].price, gItems[id].price*ui->trade.slider.val);
      else if (inv->items[slot].qty == 1)
        itoa(strBuf, gItems[id].price);
      else
        StrPrint(strBuf, "%d (%d)", gItems[id].price, gItems[id].price*inv->items[slot].qty);
      DrawText(dc->body, &fontBig, strBuf, TRADE_X+97, TRADE_Y+68);
      itoa(strBuf, gItems[id].weight);
      DrawText(dc->body, &fontBig, strBuf, TRADE_X+97, TRADE_Y+86);
    }
  }

  // Draw Buy/Sell Buttons
  if (ui->trade.buttonBuy)
    PxBlot(dc->body, ui->trade.buttonBuy, TRADE_BUY_X+1, TRADE_BUTTON_Y+1);
  else if (ui->trade.buttonSell)
    PxBlot(dc->body, ui->trade.buttonSell, TRADE_SELL_X+1, TRADE_BUTTON_Y+1);

  // Close Button
  if (ui->closeHover)
    PxBlot(dc->body, &CloseButtonHover, TRADE_CLOSE_X1+1, TRADE_CLOSE_Y1+1);
}

U0 ButtonNew(Button *button, I32 x, I32 y, I32 w, I32 h, U8* str,
             U8 color, U8 colorTrim, U8 colorBorder,
             U8 colorHover, U8 colorTrimHover, U8 colorBorderHover) {
  button->pos.x = x;
  button->pos.y = y;
  button->size.x = w;
  button->size.y = h;
  button->str = MAlloc(StrLen(str)+1);
  StrCpy(button->str, str);
  button->textPos.x = x+(button->size.x-GetTextWidth(&fontBig, str))>>1;
  button->textPos.y = y+(button->size.y-fontBig.y)>>1;
  button->colorActive = color;
  button->colorTrimActive = colorTrim;
  button->colorBorderActive = colorBorder;
  button->color = color;
  button->colorTrim = colorTrim;
  button->colorBorder = colorBorder;
  button->colorHover = colorHover;
  button->colorTrimHover = colorTrimHover;
  button->colorBorderHover = colorBorderHover;
  button->state = BUTTON_NORMAL;
}


U0 DrawButton(U8 *fb, Button *button) {
  DrawPanel(fb, button->pos, button->size, button->colorActive, button->colorBorderActive, button->colorTrimActive);
  I32 ty = button->textPos.y;
  if (button->state == BUTTON_HOVER)
    ty++;
  DrawText(fb, &fontBig, button->str, button->textPos.x, ty);
}

/*
U0 DrawButton(U8 *fb, CD2I32 pos, CD2I32 size, U8 *str) {
  DrawPanel(fb, pos, size, SWEET_GREEN_DK, SWEET_BLACK, SWEET_GREEN);
  DrawText(fb, &fontBig, str, pos.x+(size.x-GetTextWidth(&fontBig, str))>>1, pos.y+(size.y-fontBig.y)>>1);
}
*/

Bool HandleButton(Button *button, Controls *ctrl) {
  if (button->state == BUTTON_DISABLED)
    return FALSE;
  button->state = BUTTON_NORMAL;
  button->colorActive = button->color;
  button->colorTrimActive = button->colorTrim;
  button->colorBorderActive = button->colorBorder;
  if (ms.pos.x >= button->pos.x && ms.pos.x < button->pos.x+button->size.x &&
      ms.pos.y-8 >= button->pos.y && ms.pos.y-8 < button->pos.y+button->size.y) {
    button->state = BUTTON_HOVER;
    button->colorActive = button->colorHover;
    button->colorTrimActive = button->colorTrimHover;
    button->colorBorderActive = button->colorBorderHover;
    if (ctrl->mLDown) {
      button->state = BUTTON_CLICKED;
      return TRUE;
    }
  }
  return FALSE;
}

#define ESC_MENU_W 300
#define ESC_MENU_H 300
#define ESC_MENU_X 320-ESC_MENU_W>>1
#define ESC_MENU_Y 240-ESC_MENU_H>>1

U0 InitEscMenu(EscMenuUI *menu) {
  ButtonNew(&menu->buttonMainMenu, ESC_MENU_X+ESC_MENU_W>>1-200>>1, ESC_MENU_Y+8, 200, fontBig.y+8, "MAIN MENU",
            SWEET_GREEN, SWEET_GREEN_DK, SWEET_BLACK,
            SWEET_GREEN_DK, SWEET_GREEN_DK, SWEET_WHITE);

}

U0 DrawEscMenu(U8 *fb, EscMenuUI *menu) {
  CD2I32 panelPos, panelSize;
  panelPos.x = ESC_MENU_X;
  panelPos.y = ESC_MENU_Y;
  panelSize.x = ESC_MENU_W;
  panelSize.y = ESC_MENU_H;
  DrawPanel(fb, panelPos, panelSize, SWEET_GREY, SWEET_BLACK, SWEET_GREY_LT);
  DrawButton(fb, &menu->buttonMainMenu);
}

U0 HandleEscMenu(EscMenuUI *menu, Controls *ctrl) {
  HandleButton(&menu->buttonMainMenu, ctrl);
}

#endif