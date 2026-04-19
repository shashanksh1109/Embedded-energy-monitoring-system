import api from './axios';
export const getMode = () => api.get('/mode').then(r => r.data);
export const setSimulationMode = () => api.post('/mode/simulation').then(r => r.data);
export const setHardwareMode = () => api.post('/mode/hardware').then(r => r.data);
