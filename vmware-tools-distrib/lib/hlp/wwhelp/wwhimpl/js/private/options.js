// Copyright (c) 2001-2003 Quadralay Corporation.  All rights reserved.
//

function  WWHJavaScriptSettings_Object()
{
  this.mHoverText = new WWHJavaScriptSettings_HoverText_Object();

  this.mTabs      = new WWHJavaScriptSettings_Tabs_Object();
  this.mTOC       = new WWHJavaScriptSettings_TOC_Object();
  this.mIndex     = new WWHJavaScriptSettings_Index_Object();
  this.mSearch    = new WWHJavaScriptSettings_Search_Object();
  this.mFavorites = new WWHJavaScriptSettings_Favorites_Object();
}

function  WWHJavaScriptSettings_HoverText_Object()
{
  this.mbEnabled = true;

  this.mFontStyle = "font-family:Arial; font-size: 8pt; font-weight:bold ";

  this.mWidth = 150;

  this.mForegroundColor = "***REMOVED***000000";
  this.mBackgroundColor = "***REMOVED***FFFFFF";
  this.mBorderColor     = "***REMOVED***b8b8b8";
}

function  WWHJavaScriptSettings_Tabs_Object()
{
  this.mFontStyle = "font-family: Arial; font-size: 9pt ; font-weight: normal";

  this.mSelectedTabForegroundColor = "***REMOVED***000000";

  this.mDefaultTabForegroundColor = "***REMOVED***000000";
}

function  WWHJavaScriptSettings_TOC_Object()
{
  this.mbShow = true;

  this.mFontStyle = "font-family:Arial; font-size: 8pt; font-weight:bold ";

  this.mHighlightColor = "***REMOVED***CCCCCC";
  this.mEnabledColor   = "***REMOVED***315585";
  this.mDisabledColor  = "black";

  this.mIndent = 17;
}

function  WWHJavaScriptSettings_Index_Object()
{
  this.mbShow = true;

  this.mFontStyle = "font-family:Arial; font-size: 8pt; font-weight:bold ";

  this.mHighlightColor = "***REMOVED***CCCCCC";
  this.mEnabledColor   = "***REMOVED***315585";
  this.mDisabledColor  = "black";

  this.mIndent = 17;

  this.mNavigationFontStyle      = "font-family: Verdana, Arial, Helvetica, sans-serif ; font-size: 8pt ; font-weight: bold";
  this.mNavigationCurrentColor   = "black";
  this.mNavigationHighlightColor = "***REMOVED***CCCCCC";
  this.mNavigationEnabledColor   = "***REMOVED***315585";
  this.mNavigationDisabledColor  = "***REMOVED***999999";
}

function  WWHJavaScriptSettings_Index_DisplayOptions(ParamIndexOptions)
{
  ParamIndexOptions.fSetThreshold(1);
  ParamIndexOptions.fSetSeperator(" - ");
}

function  WWHJavaScriptSettings_Search_Object()
{
  this.mbShow = true;

  this.mFontStyle = "font-family:Arial; font-size: 8pt; font-weight:bold ";

  this.mHighlightColor = "***REMOVED***CCCCCC";
  this.mEnabledColor   = "***REMOVED***315585";
  this.mDisabledColor  = "black";

  this.mbResultsByBook = true;
  this.mbShowRank      = true;
}

function  WWHJavaScriptSettings_Favorites_Object()
{
  this.mbShow = true;

  this.mFontStyle = "font-family:Arial; font-size: 8pt; font-weight:bold ";

  this.mHighlightColor = "***REMOVED***CCCCCC";
  this.mEnabledColor   = "***REMOVED***315585";
  this.mDisabledColor  = "black";
}
