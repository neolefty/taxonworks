<template>
  <div>
    <label>Field number</label>
    <input
      type="text"
      v-model="collectingEvent.verbatim_field_number"
      @change="updateChange"
    />
  </div>
</template>

<script>
import extendCE from '../../mixins/extendCE.js'

export default {
  mixins: [extendCE]
}
</script>
