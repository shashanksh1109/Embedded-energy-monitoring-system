import axios from './axios';

export const getMode = () => axios.get('/api/mode');
export const setSimulationMode = () => axios.post('/api/mode/simulation');
export const setHardwareMode = () => axios.post('/api/mode/hardware');
