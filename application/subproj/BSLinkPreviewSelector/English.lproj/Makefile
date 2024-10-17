
INFO_PLIST=../BSLInkPreviewSelector-Info.plist
LOCALIZED_INFO_PLIST_TEMPLATE=InfoPlist.strings.templ
LOCALIZED_INFO_PLIST=InfoPlist.strings

updateVersion:
	${CP} $(LOCALIZED_INFO_PLIST) $(LOCALIZED_INFO_PLIST).bak
	REV=`/usr/bin/grep -A1 'CFBundleShortVersionString' $(INFO_PLIST) | ${SED} -n -e 's:.*<string>\(.*\)</string>.*:\1:p'`;\
	${ICONV} -f UTF-16 -t UTF-8 $(LOCALIZED_INFO_PLIST_TEMPLATE) \
	 | ${SED} -e "s/%%%%VERSION%%%%/$${REV}/" \
	 | ${ICONV} -f UTF-8 -t UTF-16 > $(LOCALIZED_INFO_PLIST)

restoreInfoPlist:
	if [ -f $(LOCALIZED_INFO_PLIST).bak ] ; then /bin/mv -f $(LOCALIZED_INFO_PLIST).bak $(LOCALIZED_INFO_PLIST) ; fi

