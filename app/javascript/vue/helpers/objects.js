const copyObjectByProperties = (objSource, objProperties) => {
  const objKeys = Object.keys(objProperties)
  const newObj = Object.fromEntries(Object.entries(objSource).filter(([key]) => objKeys.includes(key)))

  return newObj
}

const isJSON = (str) => {
  try {
    return (typeof str === 'object' || (JSON.parse(str) && !!str))
  } catch (e) {
    return false
  }
}

export {
  copyObjectByProperties,
  isJSON
}
