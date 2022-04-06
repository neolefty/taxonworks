import { People } from 'routes/endpoints'
import { MutationNames } from '../mutations/mutations'

export default ({ state, commit }, params) => {
  state.isLoading = true
  state.mergeList = []

  People.where({ ...params, extend: ['roles'] }).then(response => {
    commit(MutationNames.SetMatchPeople, response.body)
    state.URLRequest = response.request.responseURL
  }).finally(_ => {
    state.isLoading = false
  })
}
