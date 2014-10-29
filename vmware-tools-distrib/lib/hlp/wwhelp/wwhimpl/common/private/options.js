// Copyright (c) 2001-2003 Quadralay Corporation.  All rights reserved.
//

function  WWHCommonSettings_Object()
{
  this.mTitle = "VMware Tools Help";

  this.mbCookies            = true;
  this.mCookiesDaysToExpire = 30;
  this.mCookiesID           = "2";

  this.mAccessible = "false";

  this.mbSyncContentsEnabled  = true;
  this.mbPrevEnabled          = true;
  this.mbNextEnabled          = true;
  this.mbRelatedTopicsEnabled = false;
  this.mbEmailEnabled         = true;
  this.mbPrintEnabled         = true;
  this.mbBookmarkEnabled      = false;
  this.mbPDFEnabled           = false;

  this.mEmailAddress = "docfeedback@vmware.com";

  this.mRelatedTopics = new WWHCommonSettings_RelatedTopics_Object();
  this.mALinks        = new WWHCommonSettings_ALinks_Object();
  this.mPopup         = new WWHCommonSettings_Popup_Object();

  this.mbHighlightingEnabled        = true;
  this.mHighlightingForegroundColor = "***REMOVED***FFFFFF";
  this.mHighlightingBackgroundColor = "***REMOVED***333399";
}

function  WWHCommonSettings_RelatedTopics_Object()
{
  this.mWidth = 250;

  this.mTitleFontStyle       = "font-family: Verdana, Arial, Helvetica, sans-serif ; font-size: 10pt";
  this.mTitleForegroundColor = "***REMOVED***FFFFFF";
  this.mTitleBackgroundColor = "***REMOVED***999999";

  this.mFontStyle       = "font-family: Verdana, Arial, Helvetica, sans-serif ; font-size: 8pt";
  this.mForegroundColor = "***REMOVED***003399";
  this.mBackgroundColor = "***REMOVED***FFFFFF";
  this.mBorderColor     = "***REMOVED***666666";

  this.mbInlineEnabled = false;
  this.mInlineFontStyle = "font-family: Verdana, Arial, Helvetica, sans-serif ; font-size: 10pt";
  this.mInlineForegroundColor = "***REMOVED***003366";
}

function  WWHCommonSettings_ALinks_Object()
{
  this.mbShowBook = false;

  this.mWidth  = 250;
  this.mIndent = 17;

  this.mTitleFontStyle       = "font-family: Verdana, Arial, Helvetica, sans-serif ; font-size: 10pt";
  this.mTitleForegroundColor = "***REMOVED***FFFFFF";
  this.mTitleBackgroundColor = "***REMOVED***999999";

  this.mFontStyle       = "font-family: Verdana, Arial, Helvetica, sans-serif ; font-size: 8pt";
  this.mForegroundColor = "***REMOVED***003399";
  this.mBackgroundColor = "***REMOVED***FFFFFF";
  this.mBorderColor     = "***REMOVED***666666";
}

function  WWHCommonSettings_Popup_Object()
{
  this.mWidth = 200;

  this.mBackgroundColor = "***REMOVED***FFFFCC";
  this.mBorderColor     = "***REMOVED***999999";
}
