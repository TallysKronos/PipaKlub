import {convert} from './core.mjs';
self.onmessage=({data})=>{try{self.postMessage({project:convert(data.source,data.settings)});}catch(error){self.postMessage({error:error.message});}};
