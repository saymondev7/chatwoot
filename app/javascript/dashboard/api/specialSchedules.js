/* global axios */
import ApiClient from './ApiClient';

class SpecialSchedulesAPI extends ApiClient {
  constructor() {
    super('special_schedules', { accountScoped: true });
  }

  create(params) {
    return axios.post(this.url, { special_schedule: params });
  }

  update(id, params) {
    return axios.patch(`${this.url}/${id}`, { special_schedule: params });
  }
}

export default new SpecialSchedulesAPI();
