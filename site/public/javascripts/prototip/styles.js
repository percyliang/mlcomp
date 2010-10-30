Prototip.Styles = {
  // The default style every other style will inherit from.
  // Used when no style is set through the options on a tooltip.
  'default': {
    border: 6,
    borderColor: '#907f6f',
    className: 'default',
    closeButton: false,
    hideAfter: false,
    hideOn: 'mouseleave',
    hook: false,
	//images: 'styles/creamy/',    // Example: different images. An absolute url or relative to the images url defined above.
    radius: 6,
	showOn: 'mousemove',
    stem: {
      //position: 'topLeft',       // Example: optional default stem position, this will also enable the stem
      height: 12,
      width: 15
    }
  },

  'protoblue': {
    className: 'protoblue',
    border: 6,
    borderColor: '#116497',
    radius: 6,
    stem: { height: 12, width: 15 }
  },

  'darkgrey': {
    className: 'darkgrey',
    border: 6,
    borderColor: '#363636',
    radius: 6,
    stem: { height: 12, width: 15 }
  },

  'creamy': {
    className: 'creamy',
    border: 6,
    borderColor: '#ebe4b4',
    radius: 6,
    stem: { height: 12, width: 15 }
  },

  'protogrey': {
    className: 'protogrey',
    border: 6,
    borderColor: '#606060',
    radius: 6,
    stem: { height: 12, width: 15 }
  }
};